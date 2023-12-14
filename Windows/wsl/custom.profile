declare _linuxDir="${dotfilesDir}/linux"
declare _linuxProfile="${_linuxDir}/custom.profile"

# Silence "Please install `package`" errors that only exist for real Linux and not WSL
source "$_linuxProfile" 2>/dev/null

export wslOsBasename="$(cat /etc/os-release | grep -E '^NAME=' | sed -E 's/[^"]+"([^"]+)"$/\1/')"
export wslWindowsPath="\\\\wsl.localhost/$wslOsBasename"
export _wslRootDir="C:/Users/$(whoami)/AppData/Local/Packages/CanonicalGroupLimited.UbuntuonWindows_79rhkp1fndgsc/LocalState/rootfs"
export hostsfile="/mnt/c/Windows/System32/drivers/etc/hosts"


# realpath: /usr/bin/java -> /etc/alternatives/jdk-X.Y.Z/bin/java
# dirname dirname: /etc/alternatives/jdk-X.Y.Z/bin/java -> /etc/alternatives/jdk-X.Y.Z
# export JAVA_HOME="$(dirname "$(dirname "$(realpath "$(which java)")")")"
export JAVA_HOME="/usr/lib/jvm/current"
export JAVA_PATH="$JAVA_HOME/bin"
export M2_HOME="$HOME/apache-maven"
export MAVEN_PATH="$M2_HOME/bin"
export GRADLE_HOME="$HOME/gradle-7.5"
export GRADLE_PATH="$GRADLE_HOME/bin"

export PATH="$JAVA_PATH:$GRADLE_PATH:$MAVEN_PATH:$PATH"


# Linux's `netstat` doesn't work nicely when nested within WSL, so use Windows' instead
alias netstat='/mnt/c/Windows/System32/NETSTAT.exe'

# Stops WSL completely. Useful for when WSL lags and/or takes up too much RAM.
alias wslStop="wsl.exe --shutdown"


topath() {
    readlink -m "$1"
}

towindowspath() {
    # The reverse of this is `wslpath` to get the Windows path in Unix form
    # See:
    #   - https://stackoverflow.com/questions/53474575/how-to-translate-the-wslpath-home-user-to-windows-path/53548414#53548414

    # See:
    #   - https://superuser.com/questions/1726309/convert-wsl-path-to-uri-compliant-wsl-localhost/1726340#1726340
    declare parsedPaths=()

    declare path=
    for path in "$@"; do
        declare path=$(topath "$path")

        # sed -e (execute script that uses regex)
        #     Allows multiple sed executions instead of only one.
        #
        # Interpretation:
        #     "/^\/mnt\//! s|/|$_wslRootDir/|"
        #         * Match any string that doesn't start with '^/mnt/' and replace '/' with '$_wslRootDir/'.
        #         * Used for the case that path is in the Linux subsystem instead of
        #           a native Windows directory (like /mnt/c or /mnt/d).
        #         * In this case, append $_wslRootDir to the beginning to get the
        #           Windows path.
        #         * `!` == "cases that don't match"
        #     "s|/mnt/\(.\)|\U\1:|"
        #         * Replace '/mnt/x' with uppercase letter and colon, i.e. 'X:'
        #         * Used for the case that path is in a native Windows directory,
        #           (e.g. /mnt/c or /mnt/d), so don't append $_wslRootDir.
        declare parsedPath=
        if isWsl; then
            # Need to escape backslashes a bunch (see: https://unix.stackexchange.com/questions/379572/escaping-both-forward-slash-and-back-slash-with-sed/379573#379573)
            parsedPath="$(echo $path | sed -e "/^\/mnt\//! s|/|\\\\\\$wslWindowsPath/|" -e "s|/mnt/\(.\)|\U\1:|")"
        else
            # Deprecated "Bash subsystem" that isn't a full Linux installation
            parsedPath=`echo $path | sed -e "/^\/mnt\//! s|/|$_wslRootDir/|" -e "s|/mnt/\(.\)|\U\1:|"`
        fi

        parsedPaths+=("$parsedPath")
    done

    # Return one single string with all parsed paths
    echo "${parsedPaths[@]}"

    # Return one single string with parsed paths wrapped by single quotes
    # argsWithStrings=`printf "'%s' " "${parsedPaths[@]}"`

    # Return paths as array
    # echo $parsedPaths
}


windows-which() {
    # See: https://stackoverflow.com/questions/304319/is-there-an-equivalent-of-which-on-the-windows-command-line/304392#304392
    declare programToSearchFor="$1"

    powershell.exe "(\$Env:Path).Split(';') | Get-ChildItem -filter *${programToSearchFor}*"
}


winGetProcess() {
    # See:
    #   - Docs: https://learn.microsoft.com/en-us/powershell/module/microsoft.powershell.management/get-process
    declare pids=("$@")
    pids=("$(array.join pids ',')")

    declare procInfo="$(powershell.exe "Get-Process -Id ${pids[@]}")"
    procInfo="$(echo "$procInfo" | trim -t 1)"
    declare numColumns="$(echo "$procInfo" | head -n 1 | awk '{ print(NF) }')"

    echo "$procInfo" | column -tc "$numColumns"
}

winGetProcessByPort() {
    # See:
    #   - https://stackoverflow.com/questions/15463593/how-to-find-out-application-name-by-pid-process-id/15498195#15498195
    declare ports=("$@")
    declare portsAsPowershellPidCommand=()

    array.map -r portsAsPowershellPidCommand ports "echo \"(Get-NetTCPConnection -LocalPort \$value).OwningProcess\""

    # winGetProcess "${portsAsPowershellPidCommand[@]}"

    declare allProcessInfo=''
    declare portCmdIndex=
    for portCmdIndex in "${!portsAsPowershellPidCommand[@]}"; do
        declare portCmd="${portsAsPowershellPidCommand[$portCmdIndex]}"
        declare procInfo="$(winGetProcess "$portCmd")"

        if (( portCmdIndex != 0 )); then
            procInfo="$(echo "$procInfo" | trim -t 3)"
        fi

        allProcessInfo+="$procInfo"
    done

    allProcessInfo="$(echo "$allProcessInfo" | trim -t 1)"

    declare numColumns="$(echo "$allProcessInfo" | head -n 1 | awk '{ print(NF); }')"

    echo "$allProcessInfo" | column -tc "$numColumns"
}

winGetCommandForPids() {
    # See:
    #   - How to get command from PID:
    #       - https://serverfault.com/a/696465
    #       - https://stackoverflow.com/a/17582576/5771107
    #   - Get-WmiObject vs Get-CimInstance: https://stackoverflow.com/a/47801130/5771107
    #   - Get-WmiObject docs: https://learn.microsoft.com/en-us/powershell/module/microsoft.powershell.management/get-wmiobject
    #   - Don't concat output with ellipses: https://stackoverflow.com/a/13735900/5771107
    #   - Multiple filter args: https://stackoverflow.com/questions/28205132/powershell-filter-not-accepting-two-conditions
    declare pids=("$@")
    declare commands=""

    declare pid=
    for pid in "${pids[@]}"; do
        declare command="$(powershell.exe "Get-CimInstance Win32_Process -Filter \"ProcessID = '$pid'\" | Select-Object CommandLine | fl")"

        # Strip leading "CommandLine : " from "CommandLine : <cmd>"
        command="$(echo "$command" | cut -d ' ' -f 3-)"
        # Strip empty lines at top of output
        command="$(echo "$command" | trim -t 2)"

        if [[ "$pid" != "${pids[0]}" ]]; then
            # Add spacing between PID command entries, but not for the first one
            echo -e '\n\n'
        fi

        echo -e "PID: $pid\n----------"
        echo "$command"
    done
}


cmd() {
    # If you need to set an alias before running a command, use
    #   cmd "doskey myAlias=myTarget && my-command args"
    #   e.g.
    #   cmd "doskey docker=$(towindowspath "$(which docker)") \$\* && mvn $@"
    #
    # See:
    #   - https://stackoverflow.com/a/20531778/5771107
    declare commandToRun="$1"

    shift

    /mnt/c/Windows/System32/cmd.exe "/C" "$commandToRun" "$@"
}

# TODO make the command below work
# subl -n `towindowspath '/mnt/d/file with spaces.txt' /home/file`
_testargs() {
    argArray=()

    # $@ is all args
    # Wrapping "$@" in double quotes preserves args that have spaces in them
    for i in "$@"; do
        parsedPath=`towindowspath "$i"`
        argArray+=("$parsedPath")
    done

    subl -n "${argArray[@]}"
}

# Makes $HOME contain the normal Windows HOME directories.
# Recommended to share the same dirs between Windows/WSL to avoid file conflict/confusion.
_linkLibraryDirs() {
    declare dirsToLink=(Desktop Documents)

    if [[ -d "$HOME/${dirsToLink[0]}" ]]; then
        return 0
    fi

    declare dir=
    for dir in "${dirsToLink[@]}"; do
        ln -s "$windowsHome/$dir" "$HOME/$dir"
    done
} && _linkLibraryDirs


changeJavaVersion() {
    sudo rm /usr/lib/jvm/current
    sudo ln -s "/usr/lib/jvm/java-${1}-openjdk-amd64" "/usr/lib/jvm/current"
}


git() {
    # WSL's Git is slower than Windows' Git, at least for repositories cloned to a Windows path rather than WSL path
    declare nativeGit="$(which git)"
    declare currentPath="$(towindowspath .)"

    if echo "$currentPath" | grep -Piq '\\\\wsl'; then
        # WSL dir, use native git
        "$nativeGit" "$@"
    else
        # Windows dir, use Windows' git
        cmd git "$@"
    fi
}


getProcessLockingFile() {
    # See: https://superuser.com/questions/117902/find-out-which-process-is-locking-a-file-or-folder-in-windows/1203347#1203347
    cmd openfiles /query /fo table | cmd find /I "$1"
}



# Add Windows PATH to Ubuntu subsystem PATH
# Replace Windows-specific directory syntax with Ubuntu's with sed:
#   1. Replace drive letters with lowercase prepended with /mnt/, e.g. `C:/` -> `/mnt/c/`
#   2. Replace Windows PATH separator `;` with Ubuntu PATH separator `:`
#   3. Replace Windows directory slash `\` with Ubuntu's `/`
export WINDOWS_PATH=$(cmd "echo %PATH%" | sed -E 's|(\w):|/mnt/\L\1|g' | sed -E 's|;|:|g' | sed -E 's|\\|/|g')
export PATH="$PATH:$WINDOWS_PATH"


if ! echo $PATH | egrep -iq '\bsubl'; then
    echo "Add the 'Sublime Text' directory to 'Environment Variables -> PATH'" >&2
else
    alias subl="subl.exe"
    # alias subl="sublime_text.exe"

    # subl() {
    #     declare pathsToOpen=("$@")
    #     declare pathsAsWindowsPaths=()
    #
    #     array.toString pathsToOpen
    #     array.map -r pathsAsWindowsPaths pathsToOpen "echo \"\$(towindowspath \"\$value\")\""
    #     array.toString pathsAsWindowsPaths
    #
    #     subl.exe "${pathsAsWindowsPaths[@]}"
    # }
fi
