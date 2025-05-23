# NOTE: /usr/java/current is a symlink to /usr/var/jdk_1.2.3 for easy changing of versions like nvm does
export JAVA_HOME="/usr/lib/jvm/current"
export GRADLE_HOME="/opt/gradle"
export LATEX_HOME="$HOME/texlive/*/bin/*linux*/"
export ANDROID_HOME="$HOME/Android/Sdk"
export ANDROID_TOOLS="$HOME/Android/Sdk/tools"
export PATH="$JAVA_HOME/bin:$GRADLE_HOME/bin:$LATEX_HOME:$ANDROID_HOME:$ANDROID_TOOLS:$PATH"

if ! [[ -f /usr/local/bin/pdflatex ]] && realpath $LATEX_HOME &>/dev/null; then
    sudo ln -s $LATEX_HOME/* /usr/local/bin/
fi


# Delete dir supposedly meant to deal with autocompletions but always has
# an empty SQLite DB
rm -rf "$HOME/.presage/"


# Change directory colors in `ls`
# LS_COLORS="${LS_COLORS}di=01;35"
# export $LS_COLORS

# Change terminal colors
# See:
#   - https://stackoverflow.com/questions/56895735/what-does-export-ps1-03336m-u-033m-03332m-h-033331m-w/65477687#65477687
# [green]\username[reset-styles]:[reset-styles][teal]\working_directory[reset-styles]$[space]
export PS1="\[\033[01;32m\]\u\[\033[00m\]:\[\033[00m\]\[\033[01;34m\]\w\[\033[00m\]\$ "


alias listupdate='sudo apt update && sudo apt list --upgradable'

alias systeminfo='inxi -SMCGx'

alias get-architecture='dpkg --print-architecture'


is-installed() {
    declare packages="$@"
    # declare packagesArray=($packages)
    declare installedPackages=()

    if [[ -z "$packages" ]]; then
        echo 'Please specify a package/command' >&2
        return 1
    fi

    declare isInstalledByApt="`apt list --installed "*$packages*" 2>/dev/null | grep 'installed'`"

    if [[ -n "$isInstalledByApt" ]]; then
        installedPackages+=('Installed by apt:' '')
        installedPackages+=("`echo "$isInstalledByApt" | egrep -o '^[^/]*'`")
    fi

    declare commandsExist="`command -v $packages`"

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
        echo "`array.join -t installedPackages '%s\n'`"
        return
    fi

    echo "$packages not installed" >&2
    return 1
}


apt-get-repositories() {
    # Inspired by: https://askubuntu.com/questions/148932/how-can-i-get-a-list-of-all-repositories-and-ppas-from-the-command-line-into-an/148968#148968
    declare _showDisabled
    declare OPTIND=1

    while getopts "d" opt; do
        case "$opt" in
            d)
                _showDisabled='^\s*#\s*'
                ;;
        esac
    done

    shift $(( OPTIND - 1 ))

    declare _aptRepoEnabledSearchRegex='^\s*'
    declare _aptRepoSearchRegex="$(
        [[ -n "$_showDisabled" ]] \
        && echo "($_showDisabled|$_aptRepoEnabledSearchRegex)" \
        || echo "$_aptRepoEnabledSearchRegex"
    )"
    declare _aptRepos

    array.fromString -d '\n' -r _aptRepos "$(egrep -r "${_aptRepoSearchRegex}deb" /etc/apt/sources.list*)"

    declare _officialRepos=()
    declare _ppas=()
    declare _additionalRepos=()

    declare _ppaDomainBashRegex='https?://ppa.launchpad.net'
    declare _ppaUserPpaInstallRegex='([^/]*/[^/]*)'
    declare _repoDomain='(http.*)'


    for _aptFileToRepoStr in "${_aptRepos[@]}"; do
        # First, split by colon to separate the filename and file content.
        # Sample output from `_aptRepos[i]`:
        # /etc/apt/sources.list.d/git-core-ppa-xenial.list:deb http://ppa.launchpad.net/git-core/ppa/ubuntu xenial main
        declare _aptRepoSplitStr
        array.fromString -d ':' -r _aptRepoSplitStr "$_aptFileToRepoStr"
        # Filename won't have colons in it, so it's safe to simply get the first array entry.
        declare _aptRepoFilePath="${_aptRepoSplitStr[0]}"
        # File content would've had colons in them (e.g. URLs).
        # Since they've been split by colon, take all the remaining entries (which are all
        # part of the file content) and join them by colon to get the original file content.
        declare _aptRepoInfoWithoutColons
        array.slice -r _aptRepoInfoWithoutColons _aptRepoSplitStr 1
        declare _aptRepoInfo="$(array.join _aptRepoInfoWithoutColons ':')"


        # Official repositories are in this file specifically.
        if [[ "$_aptRepoFilePath" =~ "official-package-repositories.list" ]]; then
            declare _officialRepo="$(echo $_aptRepoInfo | sed -E "s|.*$_repoDomain|\1|g")"

            if [[ "$_aptRepoInfo" =~ $_showDisabled ]]; then
                _officialRepo="# $_officialRepo"
            fi

            _officialRepos+=("$_officialRepo")
        # PPAs are all listed on ppa.launchpad.net
        elif [[ "$_aptRepoInfo" =~ $_ppaDomainBashRegex ]]; then
            declare _ppaName="ppa:$(echo "$_aptRepoInfo" | sed -E "s|.*$_ppaDomainBashRegex/$_ppaUserPpaInstallRegex/.*|\1|g")"

            if [[ "$_aptRepoInfo" =~ $_showDisabled ]]; then
                _ppaName="# $_ppaName"
            fi

            _ppas+=("$_ppaName")
        # Additional repositories are those you needed to add via URL, install.sh script, etc.
        else
            declare _additionalRepo="$(echo $_aptRepoInfo | sed -E "s|.*$_repoDomain|\1|g")"

            if [[ "$_aptRepoInfo" =~ $_showDisabled ]]; then
                _additionalRepo="# $_additionalRepo"
            fi

            _additionalRepos+=("$_additionalRepo")
        fi
    done


    if ! array.empty _officialRepos; then
        echo "Official repositories:"
        echo -e "$(array.join -t _officialRepos '\n')" | sort -u
        echo
    fi

    if ! array.empty _ppas; then
        echo "Official PPAs:"
        echo -e "$(array.join -t _ppas '\n')" | sort -u
        echo
    fi

    if ! array.empty _additionalRepos; then
        echo "Additional repositories:"
        echo -e "$(array.join -t _additionalRepos '\n')" | sort -u
        echo
    fi
}


apt-show-package-repo() {
    declare _aptPackages=("$@")
    declare _numAptPackages="${#_aptPackages[@]}"

    # Loop through keys of the array to track if package is last in the arg array
    declare i
    for i in $(array.keys _aptPackages); do
        declare _aptPackage="${_aptPackages[$i]}"

        # If multiple packages, then print the package name as a header
        if (( $_numAptPackages > 1 )); then
            echo "$_aptPackage"
        fi


        # Delete the first column (priority of package) via `awk`.
        #   https://stackoverflow.com/questions/15361632/delete-a-column-with-awk-or-sed/15361856#15361856
        # Higher priority numbers will be installed before lower ones (500 = not installed).
        #   https://itsfoss.com/apt-cache-command/#:~:text=By%20default%2C%20each%20installed%20package%20version%20has%20a%20priority%20of%20100%20and%20a%20non%2Dinstalled%20package%20has%20a%20priority%20of%20500.%20The%20same%20package%20may%20have%20more%20than%20one%20version%20with%20a%20different%20priority.%20APT%20installs%20the%20version%20with%20higher%20priority%20unless%20the%20installed%20version%20is%20newer.
        apt policy "$_aptPackage" \
            | grep -i "$(get-architecture)" \
            | awk '{ $1=""; print $0 }' \
            | trim \
            | str.unique


        # Print extra newline between different packages
        if (( $i != ( $_numAptPackages - 1 ) )); then
            echo
        fi
    done
}

apt-package-sizes() {
    # See:
    #   - https://linuxopsys.com/topics/list-installed-packages-by-size-on-ubuntu
    dpkg-query -Wf '${Installed-Size}\t${Package}\n' \
        | sort -n \
        | egrep -i "$@" \
        | bytesReadable -c 1
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


# Requires Sophos antivirus
scan() {
    savscan -all -rec -f -archive "$@" | grep -vi 'Using IDE file'
}
alias sophosUpdate='sudo /opt/sophos-av/bin/savupdate && /opt/sophos-av/bin/savdstatus --version'


# Shortcuts for Apache server
alias apachestart='systemctl start apache2'
alias apachestop='systemctl stop apache2'
alias apachestatus='systemctl status apache2'


workDir='/home/dpow/Documents/Google Drive/Work'
alias todo="subl '$workDir/ToDo.md'"



# See:
#   `gio` man-page: http://manpages.ubuntu.com/manpages/bionic/man1/gio.1.html
#   Google Drive IDs being unreadable: https://gitlab.gnome.org/GNOME/gvfs/-/issues/402
remoteDrivesListAll() {
    gio mount -l | grep '\->' | egrep -o '\s\S*$' | egrep -o '\S*' | sort -u
}

remoteDriveFind() {
    remoteDrivesListAll | egrep -i "$@" | decolor
}

remoteDriveIsPathDirectory() {
    gio info "$1" | egrep -i '^type' | grep -iq directory
}

remoteDriveGetFilename() {
    declare _remoteDriveFilePath="$1"
    declare _remoteDriveFilenameAttribute='standard::display-name'

    declare _remoteDriveFileName="$(
        gio info -a "$_remoteDriveFilenameAttribute" "$_remoteDriveFilePath" \
            | grep "$_remoteDriveFilenameAttribute" \
            | awk '{ $1 = ""; print $0; }' \
            | trim
    )"

    if remoteDriveIsPathDirectory "$_remoteDriveFilePath"; then
        echo "${_remoteDriveFileName}/"
    else
        echo "$_remoteDriveFileName"
    fi
}

remoteDriveGetPath() {
    declare USAGE="[OPTION...] <path...>
    Translates between a remote drive's paths' IDs (e.g. hashes) and readable names (e.g. what's in the file explorer).
    "
    declare _remoteDrive=
    declare _convertReadableToId=
    declare argsArray
    declare -A _remoteDriveGetPathOptions=(
        ['d|drive:,_remoteDrive']="Name of the remote drive's root directory."
        ['i|to-id,_convertReadableToId']="Convert readable paths to the actual ID paths used by the remote drive."
        ['USAGE']="$USAGE"
    )

    parseArgs _remoteDriveGetPathOptions "$@"
    (( $? )) && return 1


    declare _rdFinalPaths=()
    declare -A _rdSubPathOptionMap=()

    declare _rdPath
    for _rdPath in "${argsArray[@]}"; do
        if [[ -z "$_remoteDrive" ]]; then
            # Ensure the remote drive is defined if it wasn't specified by stripping
            # it out of the original string request
            for _remoteDrive in $(remoteDrivesListAll); do
                if [[ "$_rdPath" =~ ^$_remoteDrive ]]; then
                    # Short-circuit the remote-drive name-processing by using the same
                    # variable name in the for-loop, defining it as the loop executes
                    break
                fi
            done
        fi

        declare _rdFinalPath=()
        declare _rdFinalPathActual=()

        declare _rdPathSegments=()
        array.fromString -d '/' -r _rdPathSegments "$_rdPath"

        declare _rdSubPath
        for _rdSubPath in "${_rdPathSegments[@]}"; do
            declare _rdSubPathAbsolute="${_remoteDrive}/$(array.join _rdFinalPathActual '/')"

            declare _rdSubPathEntry

            if [[ -n "${_rdSubPathOptionMap["$_rdSubPath"]}" ]]; then
                _rdSubPathEntry="${_rdSubPathOptionMap["$_rdSubPath"]}"
            elif [[ -z "$_convertReadableToId" ]]; then
                # Convert from remote-drive ID(s) to readable names.
                # Since the path is already in remote-drive ID format, we can simply
                # emit the sub-path's name.
                _rdFinalPathActual+=("$_rdSubPath")
                _rdSubPathEntry="$(remoteDriveGetFilename "$(echo "$_rdSubPathAbsolute" | egrep -io ".*$_rdSubPath")")"

                _rdSubPathOptionMap["$_rdSubPath"]="$_rdSubPathEntry"
            else
                # Convert from readable remote-drive path names to their respective IDs.
                # Remote drive path ID entries never include spaces, so we can blindly join
                # them with '/' to make them real paths.
                declare _rdSubPathOptions=$(gio list "$_rdSubPathAbsolute")

                declare _rdSubPathOption
                for _rdSubPathOption in "${_rdSubPathOptions[@]}"; do
                    declare _rdSubPathOptionReadableName="$(remoteDriveGetFilename "$_rdSubPathAbsolute")"

                    _rdSubPathOptionMap["$_rdSubPathOptionReadableName"]="$_rdSubPathOption"

                    if [[ "$_rdSubPath" =~ "$_rdSubPathOptionReadableName" ]]; then
                        _rdSubPathEntry="$_rdSubPathOption"

                        break
                    fi
                done
            fi

            _rdFinalPath+=("$_rdSubPathEntry")
        done

        _rdFinalPaths+=("$(str.join -j '/' "${_rdFinalPath[@]}")")
    done

    echo "${_rdFinalPaths[@]}"
}

remoteDriveLs() {
    declare _remoteDrive="$1"
    shift

    declare _remoteDriveFilePaths=("${@:-.}")
    declare _remoteDriveFileNames=()
    # declare listAttributes='standard::display-name,standard::content-type'

    declare _remoteDriveLsAddIndentation=

    if (( $(array.length _remoteDriveFilePaths) != 1 )); then
        _remoteDriveLsAddIndentation='true'
    fi


    declare _remoteDriveFilePath
    for _remoteDriveFilePath in "${_remoteDriveFilePaths[@]}"; do
        _remoteDriveFilePath="${_remoteDrive}/${_remoteDriveFilePath}"


        declare _remoteDriveFileName="$(remoteDriveGetFilename "$_remoteDriveFilePath")"

        if [[ -n "$_remoteDriveLsAddIndentation" ]]; then
            # Only append the dir name if not the root
            _remoteDriveFileNames+=("$_remoteDriveFileName")
        fi


        if remoteDriveIsPathDirectory "$_remoteDriveFilePath"; then
            declare _remoteDriveFileSubPaths=($(gio list "$_remoteDriveFilePath"))

            declare _remoteDriveFileSubPath
            for _remoteDriveFileSubPath in "${_remoteDriveFileSubPaths[@]}"; do
                _remoteDriveFileSubPath="${_remoteDriveFilePath}/${_remoteDriveFileSubPath}"

                declare _remoteDriveFileSubPathDisplayPrefix="$([[ -n "$_remoteDriveLsAddIndentation" ]] && echo '\t')"
                declare _remoteDriveFileSubPathName="$(remoteDriveGetFilename "$_remoteDriveFileSubPath")"

                _remoteDriveFileNames+=("$(echo -e "${_remoteDriveFileSubPathDisplayPrefix}${_remoteDriveFileSubPathName}")")
            done
        fi
    done


    # Wait till after all processing is done to output file names
    # Easier to just join by newlines than change IFS + add to new arrays + iterate over each separately
    declare _remoteDriveFileNamesStr="$(array.join -t _remoteDriveFileNames '\n')"
    # Sort by name
    # Note: `gio list -l | sort -Vk 2` would normally work but we want our sort to put
    # dirs above files, and neither `gio` nor `sort` offer this type of complex functionality
    _remoteDriveFileNamesStr="$(echo -e "$_remoteDriveFileNamesStr" | sort -V)"

    # Output dirs before files
    echo -e "$_remoteDriveFileNamesStr" | egrep --color=never '/$'
    # Output files
    echo -e "$_remoteDriveFileNamesStr" | egrep --color=never '[^/]$'
}


gdriveMountRclone() {
    # See:
    #   - Rclone docs: https://rclone.org/docs/
    #   - Rclone docs on Google Drive (outdated but still helpful): https://rclone.org/drive/
    #   - Example with new Rclone API: https://ostechnix.com/mount-google-drive-using-rclone-in-linux/
    declare USAGE="[OPTION...]
    Mounts a previously-configured remote Google Drive filesystem named "google-drive"
    using Rclone to \`\$HOME/google-drive/\`.

    Ideally, Gnome Online Accounts should be used, but in the event it fails due to
    SSO or similar, Rclone is a great fallback solution.
    In fact, Rclone is more CLI friendly in that you can use standard Bash built-ins,
    like \`cd\` and \`ls\`, to traverse the file tree rather than having to use \`gio\`;
    however, it requires some manual configuration, e.g. a startup script to mount the drive.
    "
    declare _remoteDriveName=
    declare _localMountPath=
    declare argsArray
    declare -A _gdriveMountRcloneOptions=(
        ['r|remote-drive-name:,_remoteDriveName']="Name of the remote drive from \`rclone config\`."
        ['p|local-path:,_localMountPath']="Path to mount the remote drive contents."
        ['USAGE']="$USAGE"
    )

    parseArgs _gdriveMountRcloneOptions "$@"
    (( $? )) && return 1

    if [[ -z "$_remoteDriveName" ]]; then
        _remoteDriveName="google-drive"
    fi

    if [[ -z "$_localMountPath" ]]; then
        _localMountPath="$HOME/$_remoteDriveName"
    fi


    declare _rcloneRemoteDrives=($(rclone listremotes 2>/dev/null))

    if array.empty _rcloneRemoteDrives || echo "${_rcloneRemoteDrives[@]}" | egrep -vq "$_remoteDriveName"; then
        echo "Either \`rclone\` is not installed or no remote drives matching \"$_remoteDriveName\" found."
        return 1
    fi

    if ! [[ -d "$_localMountPath" ]]; then
        mkdir -p "$_localMountPath"
    fi


    if (( $(ls "$_localMountPath" | wc -l) > 0 )); then
        # Mount path already exists and is populated, so assume the remote
        # drive has already been mounted
        return 0
    fi


    # `rclone mount --vfs-cache-mode writes [...]` makes reads pull from the source (remote)
    # drive every time but batches writes (caching them to disk before submitting the
    # network request). `rclone-browser` uses it by default.
    #
    # `rclone --fast-list [...]` attempts to use fewer network requests to display files within
    # a directory since many hosts offer this as a feature. However, it disables
    # parallelization and uses more memory b/c it tries to get all the dir's details
    # in one request. It is another `rclone-browser` default, but don't use it since
    # Google Drive doesn't have said restrictions as of now.
    rclone \
        mount \
        --vfs-cache-mode writes \
        "$_remoteDriveName:/" \
        "$_localMountPath"
}

gdriveLocation() {
    # TODO
    # ls ~/.local/share/gvfs-metadata/ | grep -i google-drive | egrep -v '\.log$'
    remoteDriveFind 'google.?drive'
}

gdriveLs() {
    # Works for directories, not files
    declare gdriveDir="$(gdriveLocation)"

    remoteDriveLs "$gdriveDir" "$@"
}
_gdriveLsAutocomplete() {
    # TODO
    echo
}


# Utils for working with the trash/recycle bin.
# e.g. To move files to trash instead of deleting them immediately.
#
# See:
#   https://askubuntu.com/questions/213533/command-to-move-a-file-to-trash-via-terminal/1123631#1123631
#   Alternative apt package: https://github.com/andreafrancia/trash-cli
#       Gotten from: https://www.reddit.com/r/linuxmasterrace/comments/plift1/what_a_great_way_to_start_the_weekend_deleting/hcd70aq/

trash() {
    gio trash "$@"
}

trashInfo() {
    declare _trashInfoFile="$(echo "$@" | egrep '[^-]((\S*)|(\\ \S*))+$' | trim)"
    # declare _trashInfoFlags
    # TODO: Might not have to deal with 'my\ file.txt' b/c it's already quoted/split by Bash

    gio info "$@"
}

trashLocation() {
    echo "$HOME/.local/share/Trash"
}

trashList() {
    declare _trashedPath="${@:-.}"

    _trashedPath="($_trashedPath)|($(str.replace -g '\\' '[\\/]' "$_trashedPath"))"

    gio list trash:// | egrep "$_trashedPath"
}

trashRestore() {
    declare _trashedFileOrigLocationAttributeName='trash::orig-path'
    # declare _trashedFileOrigLocationAttributeName

    declare _trashedFile
    for _trashedFile in "$(trashList "$@")"; do
        # Get the info of a trashed file, selecting only the original path of said file.
        # `gio info` outputs all the info of a trashed file, `gio info -a` only shows the specified attribute.
        # The output will include the URI of the currently-trashed file as well as a list of all its attributes.
        # Since we only care about one, `grep` for it, remove the preceding attribute name, and remove leading/trailing spaces.
        #
        # See: https://gitlab.gnome.org/GNOME/glib/-/issues/2098
        declare _trashedFileOrigLocationUri="$(
            trashInfo -a "$_trashedFileOrigLocationAttributeName" "$_trashedFile" \
                | grep "$_trashedFileOrigLocationAttributeName" \
                | awk '{ $1 = ""; print }' \
                | trim
        )"

        declare _trashedFileOrigLocation="$(decodeUri "$_trashedFileOrigLocationUri")"

        # if [[ -z "$_trashedFileOrigLocation" ]]; then

        # Left off
        # ( _trashedFile='\media\storage\.Trash-1000\files\blah.tar.gz'; trashList "($_trashedFile)|($(str.replace -g '\\' '[\\/]' "$_trashedFile"))"; )
        # trashRestore '\media\storage\.Trash-1000\files\blah.tar.gz'

        # Ensure any NTFS file system's back-slashed paths use "correct" forward-slashed paths.
        declare _trashedFileCurrentLocation="($_trashedFile)|($(str.replace -g '\\' '[\\/]' "$_trashedFile"))"

        # _trashedFile="$(str.replace -g '\\' '/' "$_trashedFile")"

        # gio move "$_trashedFileOrigLocation"
        echo "Restored trashed file \"$_trashedFile\" from \"$_trashedFileCurrentLocation\" to \"$_trashedFileOrigLocation\""
    done
}



_notifyOfUninstalledPackages() {
    declare -A _pkgsToInstall=(
        ['simplescreenrecorder']="Recording your screen."
        # ['trash-cli']="For using \`trash\` instead of \`rm\` to move files to trash instead of deleting them immediately.\n\tSee: https://github.com/andreafrancia/trash-cli" # Gotten from: https://www.reddit.com/r/linuxmasterrace/comments/plift1/what_a_great_way_to_start_the_weekend_deleting/hcd70aq/
        ['jq']="JSON parser for Bash (see: https://github.com/stedolan/jq/wiki/Cookbook)."
        # example if-elif statement for array-of-objects filtering:
        #   cat keys-array.json | jq -r '.Keys[] | select((.KeyId | contains("some-val")) or (.KeyName | contains("some-other-val")))'
        ['gh']='GitHub CLI tool - useful for various operations, e.g. auth, API calls, etc. See: https://github.com/cli/cli/blob/trunk/docs/install_linux.md'
        ['ddcutil']='A util for controlling the brightness of external monitors.'
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
            echo "Please install \`$_pkgName\` for the following purpose:" >&2
            echo -e "\t$_pkgPurpose" >&2
        fi
    done
} && _notifyOfUninstalledPackages



monitors() {
    declare USAGE="[OPTIONS...]
    TODO
    "
    declare _monitorsList
    declare _monitorsNamesOnly
    declare _monitorsOnlyDimensions
    declare _monitorsReturnArrayName
    declare _monitorDisplayDesktopWindowId
    declare -A _monitorsOptions=(
        ['l|list,_monitorsList']="List the monitors and their information instead of modifying them."
        ['n|name-only,_monitorsNamesOnly']="Only display the names of the monitors."
        ['s|dimensions,_monitorsOnlyDimensions']="Get the specific dimensions of monitor(s)."
        ['a|return-array:,_monitorsReturnArrayName']="Return monitor dimensions as a Map into the specified variable."
        ['i|id,_monitorDisplayDesktopWindowId']="Show the desktop \"window\" ID instead of the monitor's name."
        # TODO - ['v|verbose,_monitorsVerbose']="Include extra info like DPI, rotations, etc."
    )

    parseArgs _monitorsOptions "$@"
    (( $? )) && return 1

    # Command breakdown
    #   - List all display info
    #   - Filter out all lines that aren't connected displays
    #   - Remove superfluous "connected" in output line
    #   - Replace "`width`x`height`+`x-position`+`y-position`" with space as a delimiter for easier splitting later
    #   - Move primary monitor to the top and sort the external monitors by their x-position
    #   - Remove duplicate spaces between columns
    # Alternative commands:
    #   xrandr --listactivemonitors | trim -t 1 | awk '{ print($4, $3) }' | sed -E 's/\+/ /g'
    #       - List all monitors
    #       - Remove the "Monitors:" header
    #       - Only print unique info/remove superfluous, duplicate output
    #       - Replace `+` with ` ` for X and Y position output columns
    declare _monitorsAllInfo="$(
        xrandr -q \
            | egrep --color=never '^\S+(?=\b\s*connected)' \
            | sed -E 's/(\s)connected(\s)/\1/' \
            | sed -E 's/([0-9]+)x([0-9]+)|\+|\//\1 \2/g' \
            | awk '
                BEGIN {
                    primaryMonitor = ""
                    externalMonitors = ""
                }
                {
                    # Third column will either be the width-px or "primary"
                    if ($2 == "primary") {
                        # Move "primary" to the end of the line to match format of external monitors
                        $2 = ""
                        $(NF + 1) = "primary"

                        primaryMonitor = $0
                    } else {
                        externalMonitors = externalMonitors "\n" $0
                    }
                }
                END {
                    # Show the primary monitor first, then the other monitors
                    printf("%s", primaryMonitor)
                    # Sort all other monitors in order from left to right (x-pos value)
                    # We need `printf` above to avoid double-newlines in the output
                    print(externalMonitors) | "sort -n -k 4"
                }
            ' \
            | awk '{
                # Remove rotation info since we dont need it
                # See: https://unix.stackexchange.com/a/667523/203387
                $6 = $7 = $8 = $9 = $10 = $11 = $12 = $13 = ""

                # Remove monitor physical mm size info, too
                $14 = $15 = $16 = ""

                print($0)
            }' \
            | tr -s ' ' \
            | sed -E 's/\s{2,}/ /g'
    )"

    declare _monitorsOrigIFS="$IFS"
    declare IFS=$'\n'
    declare _monitorsAllInfoArr=($_monitorsAllInfo)
    declare _numMonitors=${#_monitorsAllInfoArr[@]}
    IFS="$_monitorsOrigIFS"

    # Format:
    # array[monitorIndex]=(width height x-offset y-offset)
    # where offset is the pixel where that screen's x/y begins.
    # i.e. For default multi-monitor setups using X11/Xorg, there is only 1 "desktop"
    # even if it has multiple screens.
    # This means that `wmctrl` and `xprop` only see one giant screen, and the offset is how
    # they determine where each screen starts/ends.
    # e.g. screen 1 = 1000x2000, screen 2 = 3000x500, then
    # arr=(
    #   1000 2000 0 0
    #   3000 4000 1001 750 # Last number is assuming the screen is centered based on first screen's height
    # )
    declare -A _monitorsDimsAndPos=()

    declare i
    for i in "${!_monitorsAllInfoArr[@]}"; do
        declare _monitorInfoEntry="${_monitorsAllInfoArr[i]}"
        declare _monitorInfoEntryName="$(echo "$_monitorInfoEntry" | awk '{ print $1 }')"
        declare _monitorInfoEntryDimsAndPos=($(echo "$_monitorInfoEntry" | awk '{ $1 = ""; print($2, $3, $4, $5); }'))

        _monitorsDimsAndPos["$_monitorInfoEntryName"]="${_monitorInfoEntryDimsAndPos[@]}"
    done


    # Pretty-print via `column` (see `parseArgs()` for usage info)
    declare _monitorsAllInfoNumColumns="$(echo "$_monitorsAllInfo" | grep -i primary | wc -w)"
    declare _monitorName=

    if [[ -n "$_monitorsList" ]]; then
        # Alternative: `xrandr --listactivemonitors` outputs:
        #   [index]: +[name] [width-pixels]/[width-physical]x[height-pixels]/[height-physical]+[x]+[y]
        {
            echo "Name Res(WxH) Pos(x,y)"
            echo -e "$_monitorsAllInfo" | awk '{
                # Match the above header format
                condensedDisplay = sprintf("%s %sx%s %s,%s", $1, $2, $3, $4, $5);

                # Get any additional trailing info and remove leading/trailing whitespace
                # Note: `substr($0, index($0, $6))` doesnt work because awk string commands
                # work by characters, not words, and $6 might exist earlier in the $0 string
                $1 = $2 = $3 = $4 = $5 = "";
                trimmedRemainingColumns = gensub(/^\s*(.+)\s*$/, "\\1", "g", $0);

                print(condensedDisplay, trimmedRemainingColumns);
            }'
        } | column -t -c $_monitorsAllInfoNumColumns
    elif [[ -n "$_monitorsNamesOnly" ]]; then
        for _monitorName in "${!_monitorsDimsAndPos[@]}"; do
            echo "$_monitorName"
        done
    elif [[ -n "$_monitorsOnlyDimensions" ]]; then
        for _monitorName in "${!_monitorsDimsAndPos[@]}"; do
            echo "${_monitorsDimsAndPos["$_monitorName"]}"
        done
    elif [[ -n "$_monitorDisplayDesktopWindowId" ]]; then
        echo "TODO"
        # windows -l | egrep '^\S+ -1' | awk '{ print $1 }'
    fi

    if [[ -n "$_monitorsReturnArrayName" ]]; then
        declare -n _retMonitorsList="$_monitorsReturnArrayName"

        for _monitorName in "${!_monitorsDimsAndPos[@]}"; do
            _retMonitorsList["$_monitorName"]="${_monitorsDimsAndPos["$_monitorName"]}"
        done
    fi
}



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
        ['d|display:,_display']='Display whose brightness to change (default = external monitor 1).'
        ['r|reset,_resetValue']='Resets brightness setting back to 100% (only for `xrandr`)'
        ['USAGE']="$USAGE"
        [':']=
    )

    parseArgs optsConfig "$@"
    (( $? )) && return 1

    # Default to first external monitor if display not specified
    # TODO Is the first display number still 1 if it's a tower without internal display?
    _display="${_display:-1}"
    declare _brightness="${argsArray[0]}"


    if isDefined ddcutil; then
        (
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
            sudo ddcutil --display "$_display" setvcp "$_brightnessVcpCode" "$_brightness"
        else
            sudo ddcutil --display "$_display" getvcp "$_brightnessVcpCode"
        fi
        ) 2>/dev/null

        if ! (( $? )); then
            # If there was an error, fallback to `xrandr` logic below
            return
        fi
    fi


    # `xrandr` only changes display configs through software, not hardware like DDC
    # does, so it won't change the "actual" brightness of the monitor, only the
    # brightness of the OS' processing of display output.
    # Ref: https://askubuntu.com/questions/894465/changing-the-screen-brightness-of-the-external-screen
    if [[ -z "$_resetValue" ]] && [[ -z "$_brightness" ]]; then
        # If not resetting the value and no new value defined, then return current brightness level
        declare _displayBrightnesses=($(xrandr --verbose | grep -i brightness | egrep -o '\S*$'))

        echo "${_displayBrightnesses[_display]}"

        return
    fi

    if [[ -n "$_resetValue" ]]; then
        _brightness="1"  # Reset brightness back to 100% through '-1'
    fi

    declare _displayOutputNames=($(xrandr -q | egrep -o '^\S+(?=\b\s*connected)'))
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
        -r <max|min> \t| Resize window to maximize/minimize.
        -u \t\t| Undoes the \`-r\` command.
    " | column -t -s$'\t') #

    declare _window=':ACTIVE:'
    declare _windowSelectorFlag=
    declare _resizeCmd=
    declare _resizeDirection=add
    declare _moveCmd=
    declare OPTIND=1

    while getopts "hlw:m:r:u" opt; do
        case "$opt" in
            l)
                # wmctrl doesn't include headers, so add them manually.
                #
                # The second column for monitors is -1, and 0 for application windows.
                # To only show monitors rather than windows, add this after `wmctrl` but before `sort`:
                # egrep -i '^\S+ -1'
                declare _windowListHeader="WinID\tMonitor\tPID\tx\ty\tw\th\tMachine\tWinName"
                # x-offset, y-offset, width, height
                declare _windowListInfo="$(wmctrl -lGp | sort -n -k 4 -k 3)"

                declare _windowListInfoFormatted="$(
                    echo -e "$_windowListInfo" \
                    | awk '{
                        outputWithTabsSeparatingCols = $1;
                        $1 = "";

                        # Separate columns defined by the above header by tabs since window
                        # names might have spaces in them
                        for (i = 2; i < 9; i++) {
                            outputWithTabsSeparatingCols = outputWithTabsSeparatingCols "\t" $i;

                            # Delete the header-specified entry so we can print long window
                            # names afterwards
                            $i = "";
                        }

                        trimmedRemainingColumns = gensub(/^\s*(.+)\s*$/, "\\1", "g", $0);

                        printf("%s\t%s\n", outputWithTabsSeparatingCols, trimmedRemainingColumns);
                    }'
                )"

                echo -e "$_windowListHeader\n$_windowListInfoFormatted" | column -t -c 9 -s $'\t'

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
            m)
                array.fromString -d , -r _moveCmd "$OPTARG"
                ;;
            r)
                case "$OPTARG" in
                    max)
                        _resizeCmd="maximized_vert,maximized_horz"
                        ;;
                    min)
                        # TODO - Not sure why this doesn't work but it's suggested to use xdotool
                        # See: https://askubuntu.com/questions/4876/can-i-minimize-a-window-from-the-command-line
                        _resizeDirection="toggle"
                        _resizeCmd="hidden"
                        ;;
                    *)
                        echo "Invalid option for -r" >&2
                        echo -e "$USAGE"
                        return
                        ;;
                esac
                ;;
            u)
                # Undoes the maximize/minimize
                _resizeDirection=remove
                _resizeCmd="maximized_vert,maximized_horz"
                ;;
            *)
                echo -e "$USAGE"
                return
        esac
    done

    shift $(( OPTIND - 1 ))


    # Format:
    # array[monitorName]=(width height x-offset y-offset)
    # where offset is what pixel that screen's x/y begins.
    # i.e. For default multi-monitor setups using X11/Xorg, there is only 1 "desktop"
    # even if it has multiple screens.
    # This means that `wmctrl` and `xprop` only see one giant screen, and the offset is how
    # they determine where each screen starts/ends.
    # e.g. monitor-1 = 1000x2000, monitor-2 = 3000x4000, then
    # arr=(
    #   [monitor-1]="1000 2000 0 0"
    #   [monitor-2]="3000 4000 1000 2000"
    # )
    declare _monitorDimensionsArray=($(monitors -s))
    declare -A _monitorsAndDimensionsMatrix=()

    monitors -a _monitorsAndDimensionsMatrix

    declare _numMonitors="${#_monitorDimensionsArray[@]}"

    declare _monitorName=
    for _monitorName in "${!_monitorsAndDimensionsMatrix[@]}"; do
        # Remove any punctuation, e.g. WxH or x,y
        declare _monitorDims=($(
            echo "${_monitorsAndDimensionsMatrix["$_monitorName"]}" \
            | sed -E 's/[^0-9.]/ /g'
        ))

        _monitorDimensionsArray["$_monitorName"]="${_monitorDims[@]}"
        _monitorsAndDimensionsMatrix["$_monitorName,w"]="${_monitorDims[0]}"
        _monitorsAndDimensionsMatrix["$_monitorName,h"]="${_monitorDims[1]}"
        _monitorsAndDimensionsMatrix["$_monitorName,x"]="${_monitorDims[2]}"
        _monitorsAndDimensionsMatrix["$_monitorName,y"]="${_monitorDims[3]}"
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
        declare _toMonitor="${_moveCmd[0]}"
        declare _toX="${_moveCmd[1]}"
        declare _toY="${_moveCmd[2]}"
        declare _toWidth="${_moveCmd[3]}"
        declare _toHeight="${_moveCmd[4]}"

        if (( _toMonitor >= _numMonitors )); then
            echo "Selected monitor index ($_toMonitor) too high. Please choose between [0,$(( _numMonitors - 1 ))]." >&2
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

        declare _toMonitorOffsetX=${_monitorsAndDimensionsMatrix[$_toMonitor,x]}
        declare _toMonitorOffsetY=${_monitorsAndDimensionsMatrix[$_toMonitor,y]}

        declare _correctX=$(( _toX + _toMonitorOffsetX ))
        declare _correctY=$(( _toY + _toMonitorOffsetY ))

        $_windowCmdPrefix -e "0,$_correctX,$_correctY,$_toWidth,$_toHeight"
    fi

    if [[ -n "$_resizeCmd" ]]; then
        $_windowCmdPrefix -b "${_resizeDirection},${_resizeCmd}"
    fi
}


reconnectBluetoothMouse() {
    # Mouse only allows one connection so switching OSes/computers results in it
    # not being able to reconnect to Linux. To simplify the disconnect/reconnect
    # process such that you can avoid the annoying GUI, run this command.
    declare USAGE="[OPTIONS...]
    Reconnects the Bluetooth mouse.
    "
    declare _onlyReconnect=
    declare -A _reconnectBluetoothMouseOptions=(
        ['r|reconnect-only,_onlyReconnect']="Reconnect without disconnecting first."
        ['USAGE']="$USAGE"
    )

    parseArgs _reconnectBluetoothMouseOptions "$@"
    (( $? )) && return 1

    declare _bluetoothMouseAlreadyConnectedUuid="$(
        bluetoothctl paired-devices \
            | egrep -i 'Bluetooth.*Mouse' \
            | awk '{ print $2 }'
    )"

    if [[ -z "$_onlyReconnect" ]] && [[ -n "$_bluetoothMouseAlreadyConnectedUuid" ]]; then
        bluetoothctl remove "$_bluetoothMouseAlreadyConnectedUuid"

        # Give the Bluetooth-disconnect command some time to run
        sleep 3
    fi

    # Scanning is required before discovering new Bluetooth devices, so ensure the OS knows the device exists
    ( bluetoothctl scan on ) &
    sleep 4
    kill "$!" 2>/dev/null

    declare _bluetoothMouseAvailableUuid="$(
        bluetoothctl devices \
            | egrep -i 'Bluetooth.*Mouse' \
            | awk '{ print $2 }'
    )"
    declare _bluetoothMouseInfo=

    if [[ -n "$_bluetoothMouseAvailableUuid" ]]; then
        _bluetoothMouseInfo="$(bluetoothctl info "$_bluetoothMouseAvailableUuid")"
    fi

    if [[ -n "$_bluetoothMouseAvailableUuid" ]]; then
        # Sometimes the mouse is considered as "already paired" so run the `pair`
        # command in the background to avoid the function breaking upon error
        ( bluetoothctl pair "$_bluetoothMouseAvailableUuid" ) &

        sleep 2

        kill "$!" 2>/dev/null
    fi

    # Likewise, sometimes the `connect` command will often continue searching for devices
    # and outputting their info indefinitely, so kill the remaining process if present
    ( echo "$_bluetoothMouseAvailableUuid"; bluetoothctl connect "$_bluetoothMouseAvailableUuid" ) &

    sleep 3

    kill "$!" 2>/dev/null
    # kill "$(listprocesses -i "$_bluetoothMouseAvailableUuid" | trim -t 1 | awk '{ print $2 }')" 2>/dev/null
}



recoverDeletedFileContents() {
    # See:
    #   - https://unix.stackexchange.com/questions/149342/can-overwritten-files-be-recovered/150423#150423
    declare searchRegex="$1"
    # e.g. `sda1` or `nvme0n1p1`
    declare drivesToSearch="$(
        lsblk \
        | egrep 'part\s+/' \
        | awk '{ print $1 }' \
        | egrep -o --color=never '[a-zA-Z0-9]+'
    )"
    # e.g. `/dev/sda1` or `/dev/nvme0n1p1`
    declare drivesToSearchFormattedWithDevPath="$(
        echo "$drivesToSearch" \
        | awk '{ printf("/dev/%s ", $1) }'
    )"

    egrep -i -a -B100 -A100 "$searchRegex" "$drivesToSearchFormattedWithDevPath"
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
    declare pythonSymlinkPath="$(which python3)"
    declare pythonExecutablePath="$(readlink -f "$pythonSymlinkPath")"
    declare executableDir="$(dirname "$pythonExecutablePath")"
    # TODO Could also just use `basename "$pythonExecutablePath"`
    declare currentPythonVersion="$(echo "$pythonExecutablePath" | sed -E 's|.*/([^/]*)$|\1|')"
    declare allAvailableVersions="$(ls "$executableDir" | egrep -o 'python\d\.\d+' | sort -ru)"
    declare allPython3Versions="$(echo "$allAvailableVersions" | grep 3)"
    declare latestVersion="$(echo "$allPython3Versions" | head -n 1)"
    declare oldestVersion="$(echo "$allPython3Versions" | tail -n 1)"

    # Allow using anything newer than the oldest rather than restricting to only the newest
    if [[ "$currentPythonVersion" != "$latestVersion" ]]; then
        echo 'Your python version is out of date. Please run this command:' >&2
        echo "    sudo rm /usr/bin/python3 && sudo ln -s $executableDir/$latestVersion /usr/bin/python3" >&2
    fi
} && _checkPythonVersion
