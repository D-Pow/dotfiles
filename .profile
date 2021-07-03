# ~/.profile: executed by the command interpreter for login shells.
# This file is not read by bash(1), if ~/.bash_profile or ~/.bash_login
# exists.
# see /usr/share/doc/bash/examples/startup-files for examples.
# the files are located in the bash-doc package.

# the default umask is set in /etc/profile; for setting the umask
# for ssh logins, install and configure the libpam-umask package.
# umask 022

# if running bash
if [ -n "$BASH_VERSION" ]; then
    # include .bashrc if it exists
    if [ -f "$HOME/.bashrc" ]; then
    . "$HOME/.bashrc"
    fi
fi

if [[ -z "$1" ]] || [[ -z "$2" ]]; then
    echo 'Error: Please specify the dotfiles directory and platform when sourcing.
    Usage:
        source "path/to/dotfiles/.profile" "path/to/dotfiles" "platform_or/nested/dir"

    Note: Do not append "/" to the end of directories.

    Example:
        # Must be absolute path; you cannot `source` relative paths, including `~`
        dotfilesDir="/home/repositories/dotfiles"
        platform="linux"

        source "$dotfilesDir/.profile" "$dotfilesDir" "$platform"
    '

    return 1
fi

export dotfilesDir="$1"

platform="$2"
platformDir="$dotfilesDir/$platform"
commonsDir="$dotfilesDir/bash-commons"

export commonProfile="$commonsDir/common.profile"
export customProfile="$platformDir/custom.profile"
export actualProfile='~/.profile'

source "$commonProfile"
source "$customProfile"

# Overwritten profile content based on relevant paths
alias editprofile="subl -n -w '$customProfile' && source $actualProfile"
alias editcommon="subl -n -w '$commonProfile' && source $actualProfile"
alias editactual="subl -n -w $actualProfile && source $actualProfile"

# Always source dotfiles/linux/bin/ since it has many useful scripts
export PATH="$dotfilesDir/linux/bin:$platformDir/bin:$HOME/bin:$HOME/.local/bin:$PATH"
