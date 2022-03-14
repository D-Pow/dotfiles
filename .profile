# ~/.profile: executed by the command interpreter for login shells.
# This file is not read by bash(1), if ~/.bash_profile or ~/.bash_login
# exists.
# see /usr/share/doc/bash/examples/startup-files for examples.
# the files are located in the bash-doc package.

# the default umask is set in /etc/profile; for setting the umask
# for ssh logins, install and configure the libpam-umask package.
# umask 022



_origShell="$(echo "$0" | sed -E 's/^-//')"

# Set SHELL environment to user's default shell.
# It doesn't always update even after calling `chsh -s /my/new/shell` so update it here.
#   See: https://www.gnu.org/software/bash/manual/bash.html#index-SHELL
export SHELL="$(which "$_origShell")"


isLoginShell() {
    # Login shells could be a live (interactive) user's shell or scripts using `#!/usr/bin/env bash -l`
    #
    # `-q` is the equivalent of `{ shopt -s | egrep -iq 'login_shell'; }`
    shopt -q login_shell
}



# A recent update did the horrible sin of making a non-login shell source $HOME/.profile
# which breaks Xsession, Wayland, everything.
# Thus, if the file exists and tries to source what should ONLY be sourced by login shells
# (like the terminal), tell the user to remove $HOME/.profile from the evil file's `source`
# calls in order to prevent breaking the whole system.
#
# Note: Normal, reasonable login shells (like the terminal and user-specified apps) that
# SHOULD BE LOGIN SHELLS -- unlike `lightdm` -- won't be affected, so this change is
# both safe and beneficial.
#
# See:
#   Original post shedding light on the issue: https://unix.stackexchange.com/questions/552459/why-does-lightdm-source-my-profile-even-though-my-login-shell-is-zsh
#   Respective bug filed: https://bugs.launchpad.net/ubuntu/+source/lightdm/+bug/1468832
#   Related Xorg bug: https://bugs.launchpad.net/ubuntu/+source/xorg/+bug/1468834
#   Showing alerts in Linux: https://superuser.com/questions/31917/is-there-a-way-to-show-notification-from-bash-script-in-ubuntu
#   LightDM configs: https://unix.stackexchange.com/questions/52280/lightdm-user-session-settings-on-ubuntu
#   LightDM docs: https://wiki.archlinux.org/title/LightDM
_shouldAbortProfileSourcing() {
    declare _evilFileSourcingProfile='/usr/sbin/lightdm-session'
    declare _evilFileTextToCheck='$HOME/.profile'

    if [[ -f "$_evilFileSourcingProfile" ]] && grep -iq "$_evilFileTextToCheck" "$_evilFileSourcingProfile"; then
        zenity --error --text "
        $_evilFileSourcingProfile is calling \`source $_evilFileTextToCheck\`
        even though it's not a login shell.
        Please delete all references to $_evilFileTextToCheck within $_evilFileSourcingProfile
        in order to proceed.
        "

        exit 1
    fi


    # Alternative, manual way to check if the parent is a login shell or LightDM

    # declare _origCurrentShellMerged="$_origShell - $SHELL"
    #
    # [[ "$_origShell" != "$(basename "$SHELL")" ]] \
    #     || ! isLoginShell \
    #     || [[ "$_origCurrentShellMerged" =~ 'lightdm' ]] \
    #     || [[ "$_origCurrentShellMerged" =~ 'session' ]]

    # Return false if we shouldn't abort
    return 1
}



if _shouldAbortProfileSourcing; then
    return
fi



# Export aliases even when the shell isn't interactive so that custom scripts that
# call `source "$HOME/.profile"` will work.
# The `shopt` command MUST be used here because the utils used to determine
# paths of files/directories are aliases, not functions; this means the files
# sourced here, sourced by them, etc. won't have access to the aliases without this
# shell configuration and will crash.
# Note: Those utils must be aliases (see below), so this is the only way to do it.
shopt -s expand_aliases



# if running bash
if [ -n "$BASH_VERSION" ]; then
    # include .bashrc if it exists
    if [ -f "$HOME/.bashrc" ]; then
    . "$HOME/.bashrc"
    fi
fi



declare _profileDir="$1"


# If sourced by the running shell, regardless of where the original `source` call is, i.e.
#   `source $HOME/.profile` (contains `source dotfiles/.profile`)
#   or
#   `source /path/to/dotfiles/.profile`
# then the shell is both interactive and live.
#
# If so, then it's sourced directly by the user, not a shell script or system process,
# so they should be notified that they aren't sourcing this .profile in a safe way and
# that they should update their code accordingly.
# If not, then this is probably sourced by a custom script or interactive/login shebang
# so don't show the error because scripts are meant to be portable. We'll guess what the
# OS-specific profile directory is dynamically
if [[ -z "$1" ]] && isBeingSourced -s ; then
    echo "Error: Please specify the dotfiles OS-specific profile directory when sourcing.
    Usage:
        source path/to/dotfiles/.profile \"osDirRelativeToDotfilesDir/optionalNestedDir\"

    Note: Do not append "/" to the end of the directory.

    Examples:
        source /home/repositories/dotfiles/.profile \"linux\"
        source /home/repositories/dotfiles/.profile \"Windows/git_bash\"
    " >&2
fi


# Remove all other unused args to avoid affecting nested functions/aliases
shift $#



# Utils to get the currently running file or the directory it's in.
# These must be aliases b/c if they were functions, they'd return the
# paths of this file, not the file it's called in.
#
# As strings, Bash will perform string replacement whenever it encounters
# an alias; functions, on the other hand, are "real" code, so they're
# executed as-is without regard to their location.
#
# There are some hacky ways around this, but it's best to avoid them.
# e.g.
#   Passing args to aliases: https://askubuntu.com/questions/626458/can-i-pass-arguments-to-an-alias-command/928376#928376
#   Using aliases within functions: https://askubuntu.com/questions/1123186/how-can-i-use-an-alias-in-a-function
# Or `caller` (see: ./bash-commons/)


# Gets the absolute path of wherever the alias was called, whether it's in the terminal (resolves
# the current dir) or the file calling it (not the file this alias was defined in).
# Maintains symbolic links regardless of current location, unlike `realpath` and `readlink`.
#
# `realpath -s|--no-symlink` doesn't convert symlinks to the actual path, but only works if the
# symlink is in the path arg passed to it, i.e. it still resolves the actual path if you're already
# in the path pointed to by the symlink.
# However, `pwd` does keep the symlink in the path.
# Combining the two keeps symlinks, but since `pwd` only returns the directory, add `BASH_SOURCE`
# if it exists for files.
# Also, add `-e` to canonicalize/resolve relative paths (like `-m` except all path parts must exist).
#
# For example:
#   realpath -s /path/to/symlink/file       ->  /path/to/symlink/file
#   realpath -s /path/to/symlink/dir/file   ->  /path/to/symlink/dir/file
#   realpath -s ./file      ->  /path/to/abspath/file
#   realpath -s ./dir/file  ->  /path/to/abspath/dir/file
#   pwd [./dir]         ->  /path/to/symlink/dir
#   pwd [./dir/file]    ->  /path/to/symlink/dir/file
#   realpath -s $(pwd) [./dir]              ->  /path/to/symlink/dir
#   realpath -s $(pwd)/file [./dir/file]    ->  /path/to/symlink/dir/file
#
# NOTE: `pwd` takes the parent shell's path into account, not the file's,
# so it's best to avoid using this with `source` calls.
alias this='echo "$([[ -n "${BASH_SOURCE[0]}" ]] && realpath -se "$(cd "$(dirname "${BASH_SOURCE[0]}")"; pwd)/$(basename "${BASH_SOURCE[0]}")" || realpath -es "$(pwd)")"'
# Aliases for `this` except with absolute paths so calling parents have a choice between the two.
# These two are recommended for use with `source` so the path is always guaranteed to be resolved.
alias thisFile='echo "${BASH_SOURCE[0]}"'
alias thisDir='echo "$(realpath "$(dirname "$(thisFile)")")"'


# Don't use `thisDir` because it uses `realpath` which resolves absolute paths instead of preserving
# symlinks, which ruins some utils when dotfiles is on an external drive/mounted partition.
# e.g. `repos` resolves all directories in the same parent directory as dotfiles.
#
# Likewise, as mentioned above, don't use `this` because when first opening a new terminal or sourcing
# dotfiles/.profile, `pwd` resolves to the directory the user is in, so it would only work if
# they're currently in the dotfiles directory.
export dotfilesDir="$(dirname "$(thisFile)")"


if [[ -z "$_profileDir" ]]; then
    # Try to guess the OS-specific .profile directory based off OS
    if uname | grep -iq 'Linux'; then
        _profileDir='linux'
    elif uname | egrep -iq 'mac|darwin'; then
        _profileDir='mac'
    elif uname | egrep -iq '(CYGWIN)|(MINGW)'; then
        _profileDir='Windows/git_bash'
    fi
fi

declare _osSpecificDir="$dotfilesDir/$_profileDir"
declare _commonProfilesDir="$dotfilesDir/bash-commons"

# Always source dotfiles/linux/bin/ since it has many useful scripts
export PATH="$dotfilesDir/linux/bin:$_osSpecificDir/bin:$HOME/bin:$HOME/.local/bin:$PATH"


export commonProfile="$_commonProfilesDir/index.profile"
export customProfile="$_osSpecificDir/custom.profile"
export actualProfile="$HOME/.profile"


_editProfile() {
    declare _profileToEdit="$1"
    declare _profileToSource="${2:-$actualProfile}"

    subl -n -w "$_profileToEdit" && source "$_profileToSource"
}


# Overwritten profile content based on relevant paths
alias editprofile="_editProfile '$customProfile'"
alias editcommon="_editProfile '$commonProfile'"
alias editactual="_editProfile '$actualProfile'"


source "$commonProfile"
source "$customProfile"


# Cleanup duplicate PATH entries inserted by each OS' specific PATH requirements
# and from running `source $HOME/.profile` multiple times in one shell
export PATH="$(echo "$PATH" | str.unique -d ':')"
