export rootdir='C:/Users/D-Pow/AppData/Local/Packages/CanonicalGroupLimited.UbuntuonWindows_79rhkp1fndgsc/LocalState/rootfs'
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

# TODO make the command below work
# subl -n `towindowspath '/mnt/d/file with spaces.txt' /home/file`
testargs() {
    argArray=()

    # $@ is all args
    # Wrapping "$@" in double quotes preserves args that have spaces in them
    for i in "$@"; do
        parsedPath=`towindowspath "$i"`
        argArray+=("$parsedPath")
    done

    subl -n "${argArray[@]}"
}

clip() {
    echo "$1" | cmd clip
}


# Add Windows PATH to Ubuntu subsystem PATH
# Replace Windows-specific directory syntax with Ubuntu's with sed:
#   1. Replace drive letters with lowercase prepended with /mnt/, e.g. `C:/` -> `/mnt/c/`
#   2. Replace Windows PATH separator `;` with Ubuntu PATH separator `:`
#   3. Replace Windows directory slash `\` with Ubuntu's `/`
windowsPath=$(cmd "echo %PATH%" | sed -E 's|(\w):|/mnt/\L\1|g' | sed -E 's|;|:|g' | sed -E 's|\\|/|g')
export PATH=$PATH:$windowsPath


if ! echo $PATH | egrep -iq '\bsubl'; then
    echo "Add the 'Sublime Text' directory to 'Environment Variables -> PATH'" >&2
fi
