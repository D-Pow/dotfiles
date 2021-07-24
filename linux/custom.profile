# User stuff
JAVA_HOME="/usr/java"
GRADLE_HOME="/opt/gradle"
export JAVA_HOME
export GRADLE_HOME
export PATH="$PATH:$JAVA_HOME/bin:$GRADLE_HOME/bin"

alias python3=python3.8

# Change directory colors in `ls`
# LS_COLORS="${LS_COLORS}di=01;35"
# export $LS_COLORS

# [green]\username[white]:[teal]\working_directory[white]$[space]
export PS1="\[\033[01;32m\]\u\[\033[00m\]:\[\033[00m\]\[\033[01;34m\]\w\[\033[00m\]\$ "

alias ls='ls -Fh --color'
alias lah='ls -Flah --color'

alias egrep='grep -P'

alias listupdate='sudo apt update && sudo apt list --upgradable'

is-installed() {
    local packages="$@"
    # local packagesArray=($packages)
    local installedPackages=()

    if [[ -z "$packages" ]]; then
        echo 'Please specify a package/command'
        return
    fi

    local isInstalledByApt="`apt list --installed $packages 2>/dev/null | grep 'installed'`"

    if ! [[ -z "$isInstalledByApt" ]]; then
        installedPackages+=('Installed by apt:')
        installedPackages+=("`echo "$isInstalledByApt" | egrep -o '^[^/]*'`")
    fi

    local commandsExist="`command -v $packages`"

    if ! [[ -z "$commandsExist" ]]; then
        # Add extra line between apt-installed packages and CLI commands
        [[ ${#installedPackages[@]} -ne 0 ]] && installedPackages+=('')
        installedPackages+=('CLI commands:')
        installedPackages+=("`echo "$commandsExist"`")
    fi

    if [[ ${#installedPackages[@]} -ne 0 ]]; then
        # `echo -e` only works if the string following it has `\n` in it, but it doesn't work
        # when concatenating strings through an array.
        # `printf` has more reliable behavior across platforms and usages, so use it instead.
        # For arrays, it applies the specified pattern to each entry, effectively functioning as
        # the equivalent of `myArray.join('delimiter')`
        echo "`array.join installedPackages '%s\n'`"
        return
    fi

    echo "$packages not installed"
}

# systemctl commands:
#   status              =  shows service status
#   start               =  start a service
#   stop                =  stop a service
#   restart             =  restart a service
#   enable              =  enable a service to start at boot
#   disable             =  disable a service from starting at boot
#   list-units          =  show service names (i.e. names used for above commands)
#   list-unit-files     =  show service files themselves (i.e. what files are actually running when service starts)
# Unit entries' details:
#   avahi-daemon is used for personal computers (not servers) so they can scan for other devices on the network (printers, computers, etc.)
#   docker.socket is used for listening to Docker commands (unrelated to Docker's server, so doesn't open a port itself)
alias liststartupservices='sudo systemctl list-unit-files | grep enabled | sort'

alias scan='savscan -all -rec -f -archive'
alias sophosUpdate='sudo /opt/sophos-av/bin/savupdate && /opt/sophos-av/bin/savdstatus --version'

alias apachestart='systemctl start apache2'
alias apachestop='systemctl stop apache2'
alias apachestatus='systemctl status apache2'

copy() {
    # Linux: xclip (will need install)
    # Mac:   pbcopy
    echo -n "$1" | pbcopy
}

workDir='/home/dpow/Documents/Google Drive/Work'

alias todo="subl '$workDir/ToDo.md'"
