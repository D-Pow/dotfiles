JAVA_HOME="/usr/java"
GRADLE_HOME="/opt/gradle"
LATEX_HOME="$HOME/texlive/*/bin/*linux*/"
export JAVA_HOME
export GRADLE_HOME
export PATH="$JAVA_HOME/bin:$GRADLE_HOME/bin:$LATEX_HOME:$PATH"

if ! [[ -f /usr/local/bin/pdflatex ]] && realpath $LATEX_HOME &>/dev/null; then
    sudo ln -s $LATEX_HOME/* /usr/local/bin/
fi


# Change directory colors in `ls`
# LS_COLORS="${LS_COLORS}di=01;35"
# export $LS_COLORS

# [green]\username[white]:[teal]\working_directory[white]$[space]
export PS1="\[\033[01;32m\]\u\[\033[00m\]:\[\033[00m\]\[\033[01;34m\]\w\[\033[00m\]\$ "

# Handled in bash command-enhancements.profile
# alias ls='ls -Fh --color'
# alias lah='ls -Flah --color'

alias listupdate='sudo apt update && sudo apt list --upgradable'

alias systeminfo='inxi -SMCGx'

is-installed() {
    local packages="$@"
    # local packagesArray=($packages)
    local installedPackages=()

    if [[ -z "$packages" ]]; then
        echo 'Please specify a package/command' >&2
        return 1
    fi

    local isInstalledByApt="`apt list --installed "*$packages*" 2>/dev/null | grep 'installed'`"

    if [[ -n "$isInstalledByApt" ]]; then
        installedPackages+=('Installed by apt:' '')
        installedPackages+=("`echo "$isInstalledByApt" | egrep -o '^[^/]*'`")
    fi

    local commandsExist="`command -v $packages`"

    if [[ -n "$commandsExist" ]]; then
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
        return 0
    fi

    echo "$packages not installed" >&2
    return 1
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
    local _aptRepos

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
        local _aptRepoSplitStr
        array.fromString -d ':' -r _aptRepoSplitStr "$_aptFileToRepoStr"
        # Filename won't have colons in it, so it's safe to simply get the first array entry.
        local _aptRepoFilePath="${_aptRepoSplitStr[0]}"
        # File content would've had colons in them (e.g. URLs).
        # Since they've been split by colon, take all the remaining entries (which are all
        # part of the file content) and join them by colon to get the original file content.
        local _aptRepoInfoWithoutColons
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


workDir='/home/dpow/Documents/Google Drive/Work'
alias todo="subl '$workDir/ToDo.md'"



_notifyOfUninstalledPackages() {
    declare -A _pkgsToInstall=(
        ['simplescreenrecorder']="Recording your screen."
        ['trash-cli']="For using \`trash\` instead of \`rm\` to move files to trash instead of deleting them immediately.\n\tSee: https://github.com/andreafrancia/trash-cli" # Gotten from: https://www.reddit.com/r/linuxmasterrace/comments/plift1/what_a_great_way_to_start_the_weekend_deleting/hcd70aq/
        ['google-chrome-stable']="Add \"deb https://dl.google.com/linux/chrome/deb/ stable main\" in \"Software Sources\" in Software Updater.
    May require \`wget -q -O - https://dl.google.com/linux/linux_signing_key.pub | sudo apt-key add -\` first.
    If installing Chrome causes conflicts between \`/etc/apt/sources.list.d/additional-repositories.list\` and \`/google-chrome.list\`, then remove Chrome from additional-repositories via the Software Updater GUI.
    If all else fails, just uninstall and run \`sudo bash -c \"echo 'deb [arch=amd64] https://dl.google.com/linux/chrome/deb/ stable main' > /etc/apt/sources.list.d/google-chrome.list\"\`
    If new windows appear transparent, then turn off hardware acceleration."
    )

    declare _pkgName=

    for _pkgName in "${!_pkgsToInstall[@]}"; do
        declare _pkgPurpose="${_pkgsToInstall[$_pkgName]}"

        if ! is-installed "$_pkgName" &>/dev/null; then
            echo "Please install \`$_pkgName\` for the following purpose:"
            echo -e "\t$_pkgPurpose"
        fi
    done
} && _notifyOfUninstalledPackages



brightness() {
    declare USAGE="${FUNCNAME[0]} [-r|--reset] [-d|--display DISPLAY_NUM] [brightnessValue]
    Changes the brightness of a display of NUM [0-n], where 0 is the internal display.
    Attempt changing brightness through DDC (via \`ddcutil\`) first, falling back to \`xrandr\` only if DDC isn't setup for Linux.

    If \`brightness\` isn't specified, it reads the current value.
    "

    declare _display=
    declare _resetValue=
    declare argsArray=
    declare -A optsConfig=(
        ['d|display:,_display']='Display whose brightness to change (default = external monitor 1). 0 = internal display, 1-n = external monitors.'
        ['r|reset,_resetValue']='Resets brightness setting back to 100% (only for `xrandr`)'
        ['USAGE']="$USAGE"
    )

    parseArgs optsConfig "$@"

    declare _parseArgsRetVal="$?"

    if (( _parseArgsRetVal >= 1 )); then
        return 1
    fi

    # Default to first external monitor if display not specified
    # TODO Is the first display number still 1 if it's a tower without internal display?
    _display="${_display:-1}"
    declare _brightness="${argsArray[0]}"


    if isDefined ddcutil; then
        # `ddcutil` docs:
        #   http://www.ddcutil.com/
        # All VCP codes can be found with:
        #   ddcutil getvcp known
        #
        # ddcutil creates a new `i2c` group to handle all `/dev/i2c-n` devices.
        # To run the command without requiring `sudo`, you need to add yourself
        # as member of the group and then logout.
        # Steps:
        #   # Add yourself to the group
        #   sudo usermod your-user-name -aG i2c
        #   # Create the group if it doesn't already exist
        #   sudo groupadd --system i2c
        #   # Logout
        #   # If issues still persist, copy the sample `udev` file provided to
        #   sudo cp /usr/share/ddcutil/data/45-ddcutil-i2c.rules /etc/udev/rules.d/
        #   # If necessary, reload all `udev` rules
        #   sudo udevadm trigger
        # Refs:
        #   Docs: http://www.ddcutil.com/i2c_permissions/
        #   Blog: https://blog.tcharles.fr/ddc-ci-screen-control-on-linux/
        declare _brightnessVcpCode=10

        if [[ -n "$_brightness" ]]; then
            ddcutil --display "$_display" setvcp "$_brightnessVcpCode" "$_brightness"
        else
            ddcutil --display "$_display" getvcp "$_brightnessVcpCode"
        fi

        return 0
    fi


    # `xrandr` only changes display configs through software, not hardware like DDC
    # does, so it won't change the "actual" brightness of the monitor, only the
    # brightness of the OS' processing of display output.
    # Ref: https://askubuntu.com/questions/894465/changing-the-screen-brightness-of-the-external-screen
    if [[ -z "$_resetValue" ]] && [[ -z "$_brightness" ]]; then
        # If not resetting the value and no new value defined, then return current brightness level
        declare _displayBrightnesses=($(xrandr --verbose | grep -i brightness | egrep -o '\S*$'))

        echo "${_displayBrightnesses[_display]}"

        return 0
    fi

    if [[ -n "$_resetValue" ]]; then
        _brightness="1"  # Reset brightness back to 100% through '-1'
    fi

    declare _displayOutputNames=($(xrandr -q | egrep -o '^\S+(?=.*connected)'))

    if [[ -z "$_display" ]]; then
        echo "Please specify the display for which you want to change the brightness." >&2
        echo "Valid display values are [0$(
            declare _numDisplays=$(array.length _displayOutputNames)
            (( _numDisplays > 1 )) && echo "-$(( _numDisplays - 1 ))"
        )]." >&2
        return 1;
    fi

    declare _displayOutputSelected="${_displayOutputNames[_display]}"

    xrandr --output "$_displayOutputSelected" --brightness "$_brightness"

    echo "Set the brightness of display $_display ($_displayOutputSelected) to $_brightness/1"
}


window() {
    # TODO look into xdotool
    # It seems wmctrl was installed natively in Linux Mint 20 but xdotool was not.
    # Maybe try a mix of both depending on the user's environment, e.g.
    #   if is-installed xdotool; then ...;
    #   elif is-installed wmctrl; then ...;
    #   else throw error

    # Refs:
    # Max/Min-imizing windows
    #   https://askubuntu.com/questions/703628/how-to-close-minimize-and-maximize-a-specified-window-from-terminal
    # Getting active window
    #   `:ACTIVE:` pseudo-identifier - https://unix.stackexchange.com/questions/526503/how-to-resize-and-move-a-window-by-its-pid-using-wmctrl
    #   Manual method - https://superuser.com/questions/382616/detecting-currently-active-window
    # (Desktop == Workspace) != Screen
    #   Multi-monitor setups using X11/Xorg usually use a single screen that's the size of all monitor screens
    #   combined. This is intentional as it allows for dragging windows from one screen to another and reduces
    #   processing overhead.
    #   But it means we have to do screen math ourselves manually.

    USAGE=$(echo "${FUNCNAME[0]} [OPTIONS]
    Maximizes, minimizes, moves, and otherwise changes the display of windows from the terminal.
    Created since Linux Mint 20 botched the de-tiling of windows.\n

    Usage:
        -l \t\t| Lists all windows and desktops (workspaces).
        -w <ID|Name> \t| Target window to interact with (defaults to active window).
        -m <s,x,y,w,h> \t| Move window to screen,x,y,w,h (Note: Screen != desktop/workspace).
        -s <max|min> \t| Resize window to maximize/minimize.
        -u \t\t| Undoes the \`-s\` command.
    " | column -t -s$'\t') #

    declare _window=':ACTIVE:'
    declare _windowSelectorFlag=
    declare _resizeCmd=
    declare _resizeDirection=add
    declare _moveCmd=
    declare OPTIND=1

    while getopts "lw:m:r:uh" opt; do
        case "$opt" in
            l)
                # wmctrl doesn't include headers, so add them manually.
                # TODO Header spacing is manually set so won't work for all screen
                # resolutions, but low priority so fix later.
                echo -e "WinID Desktop x    y \tw    h    user WinName"
                wmctrl -lG
                return
                ;;
            w)
                _window="$OPTARG"

                declare _windowManualSelectPattern='(s|S|select|SELECT)'

                if [[ "$_window" =~ $_windowManualSelectPattern ]]; then
                    _window=':SELECT:'
                elif [[ "$_window" =~ [0-9]x ]]; then
                    # Window ID
                    _windowSelectorFlag='-i'
                else
                    # Window name, except force exact match rather than sloppy match
                    _windowSelectorFlag='-F'
                fi
                ;;
            r)
                case "$OPTARG" in
                    max)
                        _resizeCmd="maximized_vert,maximized_horz"
                        ;;
                    min)
                        _resizeCmd=
                        echo "Minimize has not been implemented yet. Install xdotool."
                        return
                        ;;
                    *)
                        echo "Invalid option for -s" >&2
                        echo -e "$USAGE"
                        return
                        ;;
                esac
                ;;
            u)
                # Undoes the maximize/minimize
                _resizeDirection=remove
                ;;
            m)
                array.fromString -d , -r _moveCmd "$OPTARG"
                ;;
            *)
                echo -e "$USAGE"
                return
        esac
    done

    shift $(( OPTIND - 1 ))

    # Format:
    # array[screenIndex]=(width height x-offset y-offset)
    # where offset is what pixel that screen's x/y begins.
    # i.e. For default multi-monitor setups using X11/Xorg, there is only 1 "desktop"
    # even if it has multiple screens.
    # This means that `wmctrl` and `xprop` only see one giant screen, and the offset is how
    # they determine where each screen starts/ends.
    # e.g. screen 1 = 1000x2000, screen 2 = 3000x4000, then
    # arr=(
    #   1000 2000 0 0
    #   3000 4000 1000 2000
    # )
    # Also, add a space before 'connected' to exclude 'disconnected'
    declare _screensAndDimensionsArray=($(xrandr | grep ' connected' | egrep -o '\d+x\d+\+\d+\+\d+'))
    declare -A _screensAndDimensionsMatrix=()
    declare _numScreens="${#_screensAndDimensionsArray[@]}"

    for i in "${!_screensAndDimensionsArray[@]}"; do
        declare _dimsWithSeparators="${_screensAndDimensionsArray[i]}"
        declare _dimsSeparated=($(echo "$_dimsWithSeparators" | sed -E 's|[^0-9.]| |g'))

        _screensAndDimensionsArray["$i"]="${_dimsSeparated[@]}"
        _screensAndDimensionsMatrix["$i,w"]="${_dimsSeparated[0]}"
        _screensAndDimensionsMatrix["$i,h"]="${_dimsSeparated[1]}"
        _screensAndDimensionsMatrix["$i,x"]="${_dimsSeparated[2]}"
        _screensAndDimensionsMatrix["$i,y"]="${_dimsSeparated[3]}"
    done

    # If wanting to get a window other than the active one, these will be handy
    declare _activeWindowId="$(xprop -root 32x '\t$0' _NET_ACTIVE_WINDOW | cut -f 2)"
    declare _activeWindowName="$(xprop -id $_activeWindowId _NET_WM_NAME)"


    # Could use:
    # * `-i` to select window by windowId, e.g. `wmctrl -ir $_activeWindowId`.
    # * `:ACTIVE:` to select the active/focused window.
    # * `:SELECT:` to make the user click on the window they want to modify.

    declare _windowCmdPrefix="wmctrl $_windowSelectorFlag -r $_window"

    if ! array.empty _moveCmd; then
        declare _toScreen="${_moveCmd[0]}"
        declare _toX="${_moveCmd[1]}"
        declare _toY="${_moveCmd[2]}"
        declare _toWidth="${_moveCmd[3]}"
        declare _toHeight="${_moveCmd[4]}"

        if (( _toScreen >= _numScreens )); then
            echo "Selected screen index ($_toScreen) too high. Please choose between [0,$(( _numScreens - 1 ))]." >&2
            return 1
        fi

        # If x,y,width,height are empty or 0, set to -1
        # `wmctrl` interprets -1 as "maintain current value"
        if [[ -z "$_toX" ]] || (( _toX <= 0 )); then
            _toX='-1'
        fi
        if [[ -z "$_toY" ]] || (( _toY <= 0 )); then
            _toY='-1'
        fi
        if [[ -z "$_toWidth" ]] || (( _toWidth <= 0 )); then
            _toWidth='-1'
        fi
        if [[ -z "$_toHeight" ]] || (( _toHeight <= 0 )); then
            _toHeight='-1'
        fi

        declare _toScreenOffsetX=${_screensAndDimensionsMatrix[$_toScreen,x]}
        declare _toScreenOffsetY=${_screensAndDimensionsMatrix[$_toScreen,y]}

        declare _correctX=$(( _toX + _toScreenOffsetX ))
        declare _correctY=$(( _toY + _toScreenOffsetY ))

        $_windowCmdPrefix -e "0,$_correctX,$_correctY,$_toWidth,$_toHeight"
    fi

    if [[ -n "$_resizeCmd" ]]; then
        $_windowCmdPrefix -b "${_resizeDirection},${_resizeCmd}"
    fi
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
