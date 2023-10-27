declare _linuxDir="${dotfilesDir}/linux"
declare _linuxProfile="${_linuxDir}/custom.profile"

# Silence "Please install `package`" errors that only exist for real Linux and not WSL
source "$_linuxProfile" 2>/dev/null

export _wslRootDir="C:/Users/$(whoami)/AppData/Local/Packages/CanonicalGroupLimited.UbuntuonWindows_79rhkp1fndgsc/LocalState/rootfs"


# realpath: /usr/bin/java -> /etc/alternatives/jdk-X.Y.Z/bin/java
# dirname dirname: /etc/alternatives/jdk-X.Y.Z/bin/java -> /etc/alternatives/jdk-X.Y.Z
# export JAVA_HOME="$(dirname "$(dirname "$(realpath "$(which java)")")")"
export JAVA_HOME="/usr/lib/jvm/current"
export JAVA_PATH="$JAVA_HOME/bin"
export M2_HOME="$HOME/apache-maven-3.9.5"
export MAVEN_PATH="$M2_HOME/bin"
export GRADLE_HOME="$HOME/gradle-7.5"
export GRADLE_PATH="$GRADLE_HOME/bin"

export PATH="$JAVA_PATH:$GRADLE_PATH:$MAVEN_PATH:$PATH"


topath() {
    readlink -m "$1"
}

towindowspath() {
    argArray=()

    # $@ is all args
    # Wrapping "$@" in double quotes preserves args that have spaces in them
    for i in "$@"; do
        path=$(topath "$i")
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
        parsedPath=`echo $path | sed -e "/^\/mnt\//! s|/|$_wslRootDir/|" -e "s|/mnt/\(.\)|\U\1:|"`
        argArray+=("$parsedPath")
    done

    # Return one single string with all parsed paths
    echo "${argArray[@]}"

    # Return one single string with parsed paths wrapped by single quotes
    # argsWithStrings=`printf "'%s' " "${argArray[@]}"`

    # Return paths as array
    # echo $argArray
}


windows-which() {
    # See: https://stackoverflow.com/questions/304319/is-there-an-equivalent-of-which-on-the-windows-command-line/304392#304392
    declare programToSearchFor="$1"

    powershell.exe "(\$Env:Path).Split(';') | Get-ChildItem -filter *${programToSearchFor}*"
}


cmd() {
    # For some reason, flags aren't picked up in $@, $2, etc. so just parse out the command
    commandToRun="$1"
    rest=${@/$commandToRun/""}
    /mnt/c/Windows/System32/cmd.exe "/C" "$commandToRun" $rest
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


alias netstat='/mnt/c/Windows/System32/NETSTAT.exe'



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
fi
