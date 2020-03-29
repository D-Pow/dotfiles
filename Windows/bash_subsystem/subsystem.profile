export rootdir='C:/Users/djp93/AppData/Local/Packages/CanonicalGroupLimited.UbuntuonWindows_79rhkp1fndgsc/LocalState/rootfs'
export homedir="$rootdir/home/dpow"

# alias sourceprofile='chmod a+rx /home/dpow/.profile && source /home/dpow/.profile'

alias listupdate='sudo apt update && sudo apt list --upgradable'

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
        parsedPath=`echo $path | sed -e "/^\/mnt\//! s|/|$rootdir/|" -e "s|/mnt/\(.\)|\U\1:|"`
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
    commandToRun="$1"
    rest=${@/$commandToRun/""}
    /mnt/c/Windows/System32/cmd.exe "/C" "$commandToRun" $rest
}

subl() {
    cmd subl $(towindowspath $1)
}

clip() {
    echo "$1" | cmd clip
}
