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

export dotfilesDir="/home/dpow/Documents/Repositories/dotfiles"
export commonProfile="$dotfilesDir/Common.profile"
export linuxProfile="$dotfilesDir/Linux/Linux.profile"

source "$commonProfile"
source "$linuxProfile"

# Overwritten profile content based on relevant paths
alias editprofile="subl -n -w '$linuxProfile' && source ~/.profile"
alias editcommon="subl -n -w '$commonProfile' && source ~/.profile"
alias gcmd="cat '$commonProfile' | grep -e 'alias *g' | grep -v 'grep='"

export PATH="$dotfilesDir/Linux/bin:$HOME/.local/bin:$PATH"
