# ~/.profile: executed by the command interpreter for login shells.
# This file is not read by bash(1), if ~/.bash_profile or ~/.bash_login
# exists.
# see /usr/share/doc/bash/examples/startup-files for examples.
# the files are located in the bash-doc package.

# the default umask is set in /etc/profile; for setting the umask
# for ssh logins, install and configure the libpam-umask package.
# umask 022


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


declare _osSpecificProfile="$1"


# Remove all other unused args to avoid affecting nested functions/aliases
shift $#


# Utils to get the currently running file or the directory it's in.
# These must be aliases b/c if they were functions, they'd return the
# paths of this file, not the file it's called in.
#
# As strings, Bash will perform string replacement whenever it encounters
# an alias; functions, on the other hand, are "real" code, so they're
# executed as-is without regard to their location.
alias thisFile='echo "$BASH_SOURCE"'
alias thisDir='echo "$(realpath "`dirname "$(thisFile)"`")"'


export dotfilesDir="`dirname "$(thisFile)"`" # don't use `thisDir` to preserve symlinks/`~` in resulting path (e.g. if ~/repositories is a symlink to external mounted partition)

if [[ -z "$_osSpecificProfile" ]]; then
    # Try to guess the OS-specific .profile directory based off OS
    if uname | grep -iq 'Linux'; then
        _osSpecificProfile='linux'
    elif uname | egrep -iq 'mac|darwin'; then
        _osSpecificProfile='mac'
    elif uname | egrep -iq '(CYGWIN)|(MINGW)'; then
        _osSpecificProfile='Windows/git_bash'
    fi
fi

declare _osSpecificDir="$dotfilesDir/$_osSpecificProfile"
declare _commonProfilesDir="$dotfilesDir/bash-commons"

# Always source dotfiles/linux/bin/ since it has many useful scripts
export PATH="$dotfilesDir/linux/bin:$_osSpecificDir/bin:$HOME/bin:$HOME/.local/bin:$PATH"

export commonProfile="$_commonProfilesDir/common.profile"
export customProfile="$_osSpecificDir/custom.profile"
export actualProfile='~/.profile'

source "$commonProfile"
source "$customProfile"

# Overwritten profile content based on relevant paths
alias editprofile="subl -n -w '$customProfile' && source $actualProfile"
alias editcommon="subl -n -w '$commonProfile' && source $actualProfile"
alias editactual="subl -n -w $actualProfile && source $actualProfile"


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
if [[ -z "$_osSpecificProfile" ]] && isBeingSourced -s ; then
    echo "Error: Please specify the dotfiles OS-specific profile directory when sourcing.
    Usage:
        source path/to/dotfiles/.profile \"osDirRelativeToDotfilesDir/optionalNestedDir\"

    Note: Do not append "/" to the end of the directory.

    Examples:
        source /home/repositories/dotfiles/.profile \"linux\"
        source /home/repositories/dotfiles/.profile \"Windows/git_bash\"
    " >&2
fi
