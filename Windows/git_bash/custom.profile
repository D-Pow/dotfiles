export subsystemProfile="$dotfilesDir/Windows/bash_subsystem/custom.profile"

# source "$subsystemProfile"

# alias subl='/c/Program\ Files/Sublime\ Text\ 3/subl'

export FORCE_COLOR=1

export rootdir='C:/Users/djp93'
export homedir="$rootdir"

# Note: Run `ln -s /path/to/jdkFolder /path/to/jdk-active` to make this work
# Also, add `%JAVA_PATH%` above the `/path/to/Oracle/Java/javapath` entry in PATH
export JAVA_HOME='C:/Program Files/Java/jdk-active'
export JAVA_PATH="$JAVA_HOME/bin"


workDir='/g/My Drive/Work'
alias todo="subl '$workDir/ToDo.md'"


topath() {
    readlink -m "$1"
}

towindowspath() {
    declare argArray=()

    # $@ is all args
    # Wrapping "$@" in double quotes preserves args that have spaces in them
    declare i
    for i in "$@"; do
        declare path=$(topath "$i")
        # sed -e (execute script that uses regex)
        #     Allows multiple sed executions instead of only one.
        #
        # Interpretation:
        #     "/^\/mnt\//! s|/|$rootdir/|"
        #         * Match any string that doesn't start with '^/mnt/' and replace '/' with '$rootdir/'.
        #         * Used for the case that path is in the Linux subsystem instead of
        #           a native Windows directory (like /mnt/c or /mnt/d).
        #         * In this case, append $rootdir to the beginning to get the
        #           Windows path.
        #         * `!` == "cases that don't match"
        #     "s|/mnt/\(.\)|\U\1:|"
        #         * Replace '/mnt/x' with uppercase letter and colon, i.e. 'X:'
        #         * Used for the case that path is in a native Windows directory,
        #           (e.g. /mnt/c or /mnt/d), so don't append $rootdir.
        declare parsedPath="$(echo "$path" | sed -E  "s~^/mnt/(.)~\U\1:~; s~^/(.)/~\U\1:/~; s|/|\\\\|g")"
        argArray+=("$parsedPath")
    done

    # Return one single string with all parsed paths
    echo "${argArray[@]}"

    # Return one single string with parsed paths wrapped by single quotes
    # argsWithStrings=`printf "'%s' " "${argArray[@]}"`

    # Return paths as array
    # echo $argArray
}

cmd() {
    # For some reason, flags aren't picked up in $@, $2, etc. so just parse out the command
    declare commandToRun="$1"
    declare rest="${@/$commandToRun/""}"

    /c/Windows/System32/cmd.exe "/C" "$commandToRun" "$rest"
}



getProcessLockingFile() {
    # See: https://superuser.com/questions/117902/find-out-which-process-is-locking-a-file-or-folder-in-windows/1203347#1203347
    cmd openfiles /query /fo table | cmd find /I "$1"
}



# TODO make the command below work
# subl -n `towindowspath '/mnt/d/file with spaces.txt' /home/file`
testargs() {
    declare argArray=()

    # $@ is all args
    # Wrapping "$@" in double quotes preserves args that have spaces in them
    for i in "$@"; do
        parsedPath=`towindowspath "$i"`
        argArray+=("$parsedPath")
    done

    subl -n "${argArray[@]}"
}
