JAVA_HOME="/usr/java"
GRADLE_HOME="/opt/gradle"
export JAVA_HOME
export GRADLE_HOME
export PATH="$PATH:$JAVA_HOME/bin:$GRADLE_HOME/bin"


# Change directory colors in `ls`
# LS_COLORS="${LS_COLORS}di=01;35"
# export $LS_COLORS

# [green]\username[white]:[teal]\working_directory[white]$[space]
export PS1="\[\033[01;32m\]\u\[\033[00m\]:\[\033[00m\]\[\033[01;34m\]\w\[\033[00m\]\$ "

# Handled in bash command-enhancements.profile
# alias ls='ls -Fh --color'
# alias lah='ls -Flah --color'

alias egrep='grep -P'

alias listupdate='sudo apt update && sudo apt list --upgradable'

alias systeminfo='inxi -SMCGx'

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
        installedPackages+=('Installed by apt:' '')
        installedPackages+=("`echo "$isInstalledByApt" | egrep -o '^[^/]*'`")
    fi

    local commandsExist="`command -v $packages`"

    if ! [[ -z "$commandsExist" ]]; then
        # Add extra line between apt-installed packages and CLI commands
        [[ ${#installedPackages[@]} -ne 0 ]] && installedPackages+=('')
        installedPackages+=('CLI commands:' '')
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

apt-get-repositories() {
    # Inspired by: https://askubuntu.com/questions/148932/how-can-i-get-a-list-of-all-repositories-and-ppas-from-the-command-line-into-an/148968#148968
    local _showDisabled
    local OPTIND=1

    while getopts "d" opt; do
        case "$opt" in
            d)
                _showDisabled='^\s*#\s*'
                ;;
        esac
    done

    shift $(( OPTIND - 1 ))

    local _aptRepoEnabledSearchRegex='^\s*'
    local _aptRepoSearchRegex="$(
        [[ -n "$_showDisabled" ]] \
        && echo "($_showDisabled|$_aptRepoEnabledSearchRegex)" \
        || echo "$_aptRepoEnabledSearchRegex"
    )"

    array.fromString -d '\n' -r _aptRepos "$(egrep -r "${_aptRepoSearchRegex}deb" /etc/apt/sources.list*)"

    local _officialRepos=()
    local _ppas=()
    local _additionalRepos=()

    local _ppaDomainBashRegex='https?://ppa.launchpad.net'
    local _ppaUserPpaInstallRegex='([^/]*/[^/]*)'
    local _repoDomain='(http.*)'


    for _aptFileToRepoStr in "${_aptRepos[@]}"; do
        # First, split by colon to separate the filename and file content.
        # Sample output from `_aptRepos[i]`:
        # /etc/apt/sources.list.d/git-core-ppa-xenial.list:deb http://ppa.launchpad.net/git-core/ppa/ubuntu xenial main
        array.fromString -d ':' -r _aptRepoSplitStr "$_aptFileToRepoStr"
        # Filename won't have colons in it, so it's safe to simply get the first array entry.
        local _aptRepoFilePath="${_aptRepoSplitStr[0]}"
        # File content would've had colons in them (e.g. URLs).
        # Since they've been split by colon, take all the remaining entries (which are all
        # part of the file content) and join them by colon to get the original file content.
        array.slice -r _aptRepoInfoWithoutColons _aptRepoSplitStr 1
        local _aptRepoInfo="$(array.join -s _aptRepoInfoWithoutColons ':')"


        # Official repositories are in this file specifically.
        if [[ "$_aptRepoFilePath" =~ "official-package-repositories.list" ]]; then
            local _officialRepo="$(echo $_aptRepoInfo | sed -E "s|.*$_repoDomain|\1|g")"

            if [[ "$_aptRepoInfo" =~ $_showDisabled ]]; then
                _officialRepo="# $_officialRepo"
            fi

            _officialRepos+=("$_officialRepo")
        # PPAs are all listed on ppa.launchpad.net
        elif [[ "$_aptRepoInfo" =~ $_ppaDomainBashRegex ]]; then
            local _ppaName="ppa:$(echo "$_aptRepoInfo" | sed -E "s|.*$_ppaDomainBashRegex/$_ppaUserPpaInstallRegex/.*|\1|g")"

            if [[ "$_aptRepoInfo" =~ $_showDisabled ]]; then
                _ppaName="# $_ppaName"
            fi

            _ppas+=("$_ppaName")
        # Additional repositories are those you needed to add via URL, install.sh script, etc.
        else
            local _additionalRepo="$(echo $_aptRepoInfo | sed -E "s|.*$_repoDomain|\1|g")"

            if [[ "$_aptRepoInfo" =~ $_showDisabled ]]; then
                _additionalRepo="# $_additionalRepo"
            fi

            _additionalRepos+=("$_additionalRepo")
        fi
    done


    if ! array.empty _officialRepos; then
        echo "Official repositories:"
        echo -e "$(array.join _officialRepos '\n')" | sort -u
        echo
    fi

    if ! array.empty _ppas; then
        echo "Official PPAs:"
        echo -e "$(array.join _ppas '\n')" | sort -u
        echo
    fi

    if ! array.empty _additionalRepos; then
        echo "Additional repositories:"
        echo -e "$(array.join _additionalRepos '\n')" | sort -u
        echo
    fi
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


brightness() {
    # Changes the brightness of displays 0-n, where 0 is the internal display.
    # Only changes it through software, not through DDC, so it won't change the
    # "actual" brightness, only the brightness of the OS' processing of display output.
    #
    # TODO: Use a DDC system after upgrading Linux Mint to latest
    #   (current version + Nvidia driver doesn't currently support DDC).
    #   Options: https://askubuntu.com/questions/894465/changing-the-screen-brightness-of-the-external-screen
    local _display="$1"
    local _brightness="${2:-1}" # default to resetting brightness back to 100%

    local _displayOutputNames=($(xrandr -q | egrep -o '^\S+(?=.*connected)'))

    if [[ -z "$_display" ]]; then
        echo "Please specify the display for which you want to change the brightness." >&2
        echo "Valid display values are [0$(
            local _numDisplays=$(array.length _displayOutputNames)
            (( _numDisplays > 1 )) && echo "-$(( _numDisplays - 1 ))"
        )]." >&2
        return 1;
    fi

    local _displayOutputSelected="${_displayOutputNames[_display]}"

    xrandr --output "$_displayOutputSelected" --brightness "$_brightness"

    echo "Set the brightness of display $_display ($_displayOutputSelected) to $_brightness/1"
}



_checkPythonVersion() {
    # EDIT: DO NOT CHANGE THE python3 SYMLINK!!! Nor use update-alternatives
    # Doing so will break your system, just like overwriting `python --> python3` would.
    # Instead, just make your own symlinks and put them in a dir that's read earlier in PATH
    # than /usr/bin/.
    # That way, even `/usr/bin/env python3` will read the correct Python version
    # (`env` doesn't read aliases, but it will read symlinks and anything in PATH).
    #
    # To make `python3` use more recent Python version, run:
    #   sudo rm /usr/bin/python3 && sudo ln -s /usr/bin/python3.8 /usr/bin/python3
    # Or, you could use this command to add any number of different alternative executables
    # for `python3`, great for defaulting to certain versions at different points in time:
    #   sudo update-alternatives --install /usr/bin/python3 python3 /usr/bin/python3.8 1
    #   (--install <symlinkPath> <symlinkName> <newExecutablePath> <priority>)
    #   Higher number priorities are used before lower numbers.
    #   Configure them via `sudo update-alternatives --config python3`.
    #   Ref: https://medium.com/@jeethu.samsani/upgrade-python-3-5-to-3-7-in-ubuntu-a1d4347b6a3
    local pythonSymlinkPath="$(which python3)"
    local pythonExecutablePath="$(readlink -f "$pythonSymlinkPath")"
    local executableDir="$(dirname "$pythonExecutablePath")"
    local currentPythonVersion="$(echo "$pythonExecutablePath" | sed -E 's|.*/([^/]*)$|\1|')"
    local allAvailableVersions="$(ls "$executableDir" | egrep -o 'python\d\.\d' | sort -ru)"
    local allPython3Versions="$(echo "$allAvailableVersions" | grep 3)"
    local latestVersion="$(echo "$allPython3Versions" | head -n 1)"
    local oldestVersion="$(echo "$allPython3Versions" | tail -n 1)"

    # Allow using anything newer than the oldest rather than restricting to only the newest
    if [[ "$currentPythonVersion" == "$oldestVersion" ]]; then
        echo 'Your python version is out of date. Please run this command:'
        echo "    sudo rm /usr/bin/python3 && sudo ln -s $executableDir/$latestVersion /usr/bin/python3"
    fi
}
