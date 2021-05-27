# ~/.profile: executed by the command interpreter for login shells.
# This file is not read by bash(1), if ~/.bash_profile or ~/.bash_login
# exists.
# see /usr/share/doc/bash/examples/startup-files for examples.
# the files are located in the bash-doc package.

# the default umask is set in /etc/profile; for setting the umask
# for ssh logins, install and configure the libpam-umask package.
#umask 022

# if running bash
if [ -n "$BASH_VERSION" ]; then
    # include .bashrc if it exists
    if [ -f "$HOME/.bashrc" ]; then
    . "$HOME/.bashrc"
    fi
fi

export dotfilesDir="/mnt/d/Documents/Repositories/dotfiles"
export commonProfile="$dotfilesDir/common.profile"
export subsystemProfile="$dotfilesDir/Windows/bash_subsystem/subsystem.profile"

source "$commonProfile"
source "$subsystemProfile"

# Overwritten profile content based on relevant paths
alias editprofile="subl -n -w '$subsystemProfile' && source ~/.profile"
alias editcommon="subl -n -w '$commonProfile' && source ~/.profile"

export PATH="$dotfilesDir/linux/bin:$HOME/.local/bin:$PATH"
