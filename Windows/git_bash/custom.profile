export subsystemProfile="$dotfilesDir/Windows/wsl/custom.profile"

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

alias gh="/c/Program\ Files/GitHub\ CLI/gh.exe"


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
    # If you need to set an alias before running a command, use either `doskey` or `set`:
    #   cmd "doskey myAlias=myTarget && my-command args"
    # e.g.
    #   cmd "doskey docker=$(towindowspath "$(which docker)") \$\* && mvn $@"
    #
    # Bash equivalents:
    #   `doskey` == `alias`
    #   `set` == `KEY=VAL <command>`
    #
    # See:
    #   - https://stackoverflow.com/a/20531778/5771107
    #   - https://stackoverflow.com/questions/65856576/doskey-macros-break-prompts-set-p-of-batch-scripts-when-run-from-within-same

    declare USAGE="[OPTIONS...] <cmd-and-args>
    Runs \`cmd.exe\` with the specified command (first arg) and subsequent args for said command.

    Note:
        - You cannot quote the entire command string, treat it like you would any other Bash function
          where quotes only go around separate args (unlike \`bash -c 'command arg1 arg2 ...\`).
        - To use variables declared in the 'env' flag, use \`!myVar!\` rather than \`%myVar%\`.
          Percent is used for system variables, exclamation is for local variables.
    "
    declare envEntries=()
    declare argsArray
    declare stdin
    declare -A _getEnvEntriesOptions=(
        ['e|env:,envEntries']="Env vars to set for the underlying \`cmd.exe\` call."
        [':']=
        ['?']=
        ['USAGE']="$USAGE"
    )

    parseArgs _getEnvEntriesOptions "$@"
    (( $? )) && return 1

    # See:
    #   - Running multiple commands in one line: https://stackoverflow.com/questions/8055371/how-do-i-run-two-commands-in-one-line-in-windows-cmd
    #   - Delayed expansion (allows setting vars inline):
    #       - https://superuser.com/questions/1413376/set-and-print-content-of-environment-variable-in-cmd-exe-subshell
    #       - https://superuser.com/questions/1724448/how-to-cmd-von-in-line-with-another-command-to-run-sequentially
    #   - Percent vs exclamation: https://stackoverflow.com/questions/1762851/batch-delayed-expansion-not-working
    #   - `set` docs: https://learn.microsoft.com/en-us/windows-server/administration/windows-commands/set_1
    #   - `set` vs `setx`: https://superuser.com/questions/916649/what-is-the-difference-between-setx-and-set-in-environment-variables-in-windows
    #   - Question about cmd equivalent of `export`: https://superuser.com/questions/1500272/equivalent-of-export-command-in-windows
    declare setEnvVarCommands="set $(array.join envEntries ' & set ') &"
    declare cmdFlags='/C'

    if ! array.empty envEntries; then
        cmdFlags="/V:ON /C $setEnvVarCommands"
    fi

    # Quoting \`\${argsArray[@]}\` is tricky. It usually works if the first command from
    # the array is separated from the subsequent commands but it can still cause issues
    # occasionally depending on the command string.
    #
    # e.g. This fails:
    # declare commandToRun="${argsArray[0]}"
    # declare commandArgs="${argsArray[@]:1}"
    # declare cmdArgs="$(array.toString -e argsArray)"
    # /mnt/c/Windows/System32/cmd.exe $cmdFlags $cmdArgs
    #
    # As well as this:
    # /mnt/c/Windows/System32/cmd.exe "$cmdFlags" "$commandToRun" "$commandArgs"
    #
    # And this almost works, but doesn't respect positional args:
    # /mnt/c/Windows/System32/cmd.exe $cmdFlags ${argsArray[@]}
    #
    # This works for forwarding STDIN but removes colored terminal output:
    # echo "${stdin[@]}" | /mnt/c/Windows/System32/cmd.exe $cmdFlags "${argsArray[0]}" "${argsArray[@]:1}"
    #
    # This also fails if using `makeTempPipe` for some reason:
    # exec $FD>&1 | /mnt/c/Windows/System32/cmd.exe $cmdFlags "${argsArray[0]}" "${argsArray[@]:1}"
    declare cmd="$(isWsl && echo '/mnt/c/Windows/System32/cmd.exe' || echo '/c/Windows/system32/cmd') "
    cmd+='$cmdFlags "${argsArray[0]}" "${argsArray[@]:1}"'

    if (( ${#stdin[@]} )); then
        echo "${stdin[@]}" | eval "$cmd"
    else
        eval "$cmd"
    fi
}


getProcessLockingFile() {
    # See: https://superuser.com/questions/117902/find-out-which-process-is-locking-a-file-or-folder-in-windows/1203347#1203347
    cmd openfiles /query /fo table | cmd find /I "$1"
}



# TODO make the command below work
# subl -n `towindowspath '/mnt/d/file with spaces.txt' /home/file`
_testargs() {
    declare argArray=()

    # $@ is all args
    # Wrapping "$@" in double quotes preserves args that have spaces in them
    for i in "$@"; do
        parsedPath=`towindowspath "$i"`
        argArray+=("$parsedPath")
    done

    subl -n "${argArray[@]}"
}
