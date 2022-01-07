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

if [[ -z "$1" ]]; then
    echo 'Error: Please specify the dotfiles platform when sourcing.
    Usage:
        source path/to/dotfiles/.profile "platform_or/nested/dir"

    Note: Do not append "/" to the end of directories.

    Example:
        source /home/repositories/dotfiles/.profile "linux"
    ' >&2
fi


# Utils to get the currently running file or the directory it's in.
# These must be aliases b/c if they were functions, they'd return the
# paths of this file, not the file it's called in.
#
# As strings, Bash will perform string replacement whenever it encounters
# an alias; functions, on the other hand, are "real" code, so they're
# executed as-is without regard to their location.
alias thisFile='echo "$BASH_SOURCE"'
alias thisDir='echo "$(realpath "`dirname "$(thisFile)"`")"'


if type thisDir &>/dev/null; then
    export dotfilesDir="`dirname "$(thisFile)"`" # don't use `thisDir` to preserve symlinks/`~` in resulting path (e.g. if ~/repositories is a symlink to external mounted partition)

    platform="$1"

    if [[ -z "$platform" ]]; then
        # Try to guess the platform based off OS
        if uname | grep -iq 'Linux'; then
            platform='linux'
        elif uname | egrep -iq 'mac|darwin'; then
            platform='mac'
        elif uname | egrep -iq '(CYGWIN)|(MINGW)'; then
            platform='Windows/git_bash'
        fi
    fi

    platformDir="$dotfilesDir/$platform"
    commonsDir="$dotfilesDir/bash-commons"

    # Always source dotfiles/linux/bin/ since it has many useful scripts
    export PATH="$dotfilesDir/linux/bin:$platformDir/bin:$HOME/bin:$HOME/.local/bin:$PATH"

    export commonProfile="$commonsDir/common.profile"
    export customProfile="$platformDir/custom.profile"
    export actualProfile='~/.profile'

    source "$commonProfile"
    source "$customProfile"

    # Overwritten profile content based on relevant paths
    alias editprofile="subl -n -w '$customProfile' && source $actualProfile"
    alias editcommon="subl -n -w '$commonProfile' && source $actualProfile"
    alias editactual="subl -n -w $actualProfile && source $actualProfile"
fi
