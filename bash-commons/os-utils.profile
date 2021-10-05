listprocesses() {
    if (( $# > 0 )); then
        # Include header info for what each column means
        ps aux | head -n 1

        # Print info for the desired search query.
        # Filter out the `grep` command that searches for said query
        # since it's just noise.
        # Note: grep flags can still be passed by using this method.
        ps aux | grep -v grep | egrep "$@"
    else
        # Otherwise, standard command output includes headers,
        # so no manual interaction needed.
        ps aux
    fi
}

listopenports() {
    local _listopenportsCmd=()
    local OPTIND=1

    while getopts "s" opt; do
        case "$opt" in
            s)
                _listopenportsCmd+=('sudo')
                ;;
        esac
    done

    shift $(( OPTIND - 1 ))

    # -P - Show full port numbers (`:8080` instead of `:http-alt`)
    # -n - Show full IPs (`127.0.0.1:46012` instead of `ip6-localhost:46012`)
    # -i - Show ONLY internet addresses (default `lsof` shows all open files, including processes)
    #      `-i` arg follows the format:
    #          [46][protocol][@hostname|hostaddr][:service|port]
    #      e.g.
    #          `-i 4`/`-i 6` for showing IPv4/6
    #          `-i :PORT` for showing specific port
    _listopenportsCmd+=('lsof' '-Pn' '-i')  # `-i` doesn't have to be separate, but this clarifies that it accepts args

    if [[ -n "$1" ]]; then
        # Since the `-i` arg format is very specific, just search manually for the user's
        # input to make the function more user-friendly (so they aren't forced to know
        # the `-i` arg format).
        #
        # Also, keep the header showing what each column represents by also capturing
        # keywords in the `lsof` output header.
        # Use a lookahead so that the header capture isn't colorized, otherwise both
        # the header and the search query would be colorized.
        _listopenportsCmd+=("|" "egrep" "'(?=PID.*NAME)|$1'")
    fi

    # Use `eval` instead of just `${cmd[@]}` because pipes (`|`) are really difficult to
    # escape when trying to execute the array entries directly.
    # At least running it as an array instead of a string means spaces are maintained
    eval "${_listopenportsCmd[@]}"
}


readEnvFile() {
    # Reads a .env, .properties, etc. file containing `key=value` entries
    # on separate lines.
    # Sets the keys as variables in the current shell.
    local _envFile="$1"

    # Cannot use `cat file | while read` because pipes create subshells,
    # meaning that writing to a variable stays only in that subshell, not the
    # parent (this script's) shell.
    # Thus, use the file as redirected input instead.
    #
    # Also, use `read -r` to maintain backslashes as-is rather than parse them.
    while IFS='=' read -r key value; do
        case "$key" in
            '#'*)
                # Ignore comments
                ;;
            *)
                eval "$key=$value"
                ;;
        esac
    done < "$_envFile"
}


getAllCrlfFiles() {
    # find [args] -exec [command] "output from find" "necessary `-exec` terminator to show end of command"
    find . -not -type d -exec file "{}" ";" | grep CRLF
}


getAllLinesAfter() {
    # sed -rEgex '[start_line],[end_line]/pattern/ delete_lines_before_including_pattern_match'
    sed -E "1,/$1/ d"
}


getCommandsMatching() {
    # `compgen -c` lists all commands available to bash,
    # regardless of install location or binary vs function vs alias
    compgen -c | grep -E "$1"
}


makeTempPipe() {
    # Refs:
    # https://stackoverflow.com/questions/8297415/in-bash-how-to-find-the-lowest-numbered-unused-file-descriptor/17030546#17030546
    # https://superuser.com/questions/184307/bash-create-anonymous-fifo/633185#633185

    # `mktemp` - Create a temp file
    declare _tmpPipeFile="$(mktemp)"
    # Putting a string in `exec {var}` sets the lowest available file descriptor to that variable
    exec {FD}<>"$_tmpPipeFile"

    # TODO Find out how to get return value (the following line doesn't work).
    #   Calling parent could use `$FD` or they could use `declare myPipe={ makeTempPipe }`
    #   Note: Must be run in `{ cmd }` to keep FD in same shell, not in subshell, where it'll disappear
    #
    # FD is used in the same way normal FD's are, just add a $ in front of them
    # e.g.
    #   echo hello >&$FD
    #   cat <&$FD
    #   exec $FD>&-
    # echo "$FD"

    # `trap` will ensure the temp file is deleted upon exit.
    # FD will automatically be closed upon exit, so no need to
    # close it manually with `exec "$FD">&-` in this trap
    trap 'rm -rf "$_tmpPipeFile"' EXIT QUIT INT TERM
}

getFileFromDescriptor() {
    declare _fdToSearch="$1"
    declare _lsofOutputHeaders=(COMMAND PID USER FD TYPE DEVICE SIZE_OFF NODE NAME)

    # Include this process' PID b/c it likely made the FD
    # Note: `$$` within `( someCommand )` actually usually resolves to the parent PID
    # So account for this via `BASHPID` (only supported in Bash@>=4).
    # See: https://stackoverflow.com/questions/21063765/why-is-returning-the-same-id-as-the-parent-process/21063837#21063837
    declare _fdToSearchCurrentPid="${BASHPID:-$$}"
    # Include the parent's as well in case the FD is used in a subshell or script
    declare _fdToSearchParentPid="$(ps -o ppid= "$_fdToSearchCurrentPid")"
    # `lsof` = LiSt Open Files
    # `-d` = file Descriptor
    # `-a` = And (match multiple criteria)
    # `-p` = Process ID
    # `| \` must be done instead of `\ [\n] |` since comments exist between the lines
    lsof -d "$_fdToSearch" -a -p "$_fdToSearchParentPid,$_fdToSearchCurrentPid" | \
        # truncate multiple spaces into one (allows avoiding the `\S+\s+` regex from below)
        tr -s ' ' | \
        # Get group 9 (NAME)
        cut -d ' ' -f 9 | \
        # Remove header
        grep -v NAME | \
        # Uncomment below and change `cut -f 4,9` to include both FD and file in output
        # | sed -E 's/^([0-9]+)\w/\1/' \
        # Remove duplicates in case multiple processes/FDs point to same file
        sort -u


    # Old way: Manually getting files via regex (just a bit more complicated than the above)
    # # Allows selecting an `lsof` header by index.
    # # array.map/str.repeat combo results in e.g. "^\S+\s+" for "COMMAND" and "^\S+\s+\S+\s+" for "PID"
    # declare _lsofOutputMatchers=()
    # array.map -r _lsofOutputMatchers _lsofOutputHeaders "echo \"^\$(str.repeat '\S+\s+' \$(( key + 1 )) )\""
    #
    # # Match "\S+\s+{n}(searchQuery)"
    # # Thus, index must be "searchItem - 1"
    # declare _fdMatchRegex="${_lsofOutputMatchers[2]}$_fdToSearch"
    # declare _fdFileMatchRegex="${_lsofOutputMatchers[7]}(.*)"
    # declare _fdSearchingParentPid="$$"
    #
    # lsof -d $_fdToSearch -p $_fdSearchingParentPid \
    #     | grep $_fdSearchingParentPid \
    #     | egrep "$_fdMatchRegex" \
    #     | esed "s|$_fdFileMatchRegex|\1|"
}



_copyCommand=
_pasteCommand=

copy() {
    # Create new `copy` command for writing content to the clipboard.
    # Can be used with both piping `echo "hi" | copy` and with args `copy "hi"`.
    #
    #
    # Input from `&0` and/or `/dev/stdin` can be piped directly to another command,
    # e.g. what is done in most of the `git.profile` functions.
    #
    # However, to handle entries individually, like how `find` outputs each discovered
    # match one-by-one to `&1`, then a `read` call must be made.
    #
    # This can be done by either:
    # 1) "Parallel"/piping output as it's processed, per-entry, in a loop:
    #       while read inputLine; do
    #           echo "$inputLine"
    #       done
    # 2) "Sequential"/non-piping to collect all input before doing anything:
    #       `readarray -t inputArray`
    #     Where `readarray` == `mapfile`, both of which are array-friendly versions of `read`
    #
    # Both use IFS to determine distinct entries, so something
    # like `echo 'a b' c | myFunc` will read `a b c` as one entry.
    #
    # Note that `stdin=("$(cat -)")` doesn't work b/c it calls `cat` in a subshell,
    # so all IFS-separated entries are now combined into one.
    # We could do something like `eval 'stdin=("$(cat -)")'` to execute the logic in
    # this current shell, but then we run into issues with spaces, newlines, etc.
    # Alternatively, we could use `<<<&0` or something, but that gets even more complicated.
    # Avoid that mess by just using the built-in, more user-friendly, `readX` functions.
    #
    # Ref: https://stackoverflow.com/questions/5130968/how-can-i-copy-the-output-of-a-command-directly-into-my-clipboard/62517779#62517779
    local _toCopyArgs=("$@")
    local _toCopyStdin=()

    if array.empty _toCopyArgs; then
        readarray -t _toCopyStdin
    fi

    echo -n "${_toCopyStdin[@]}" "${_toCopyArgs[@]}" | $_copyCommand
}

paste() {
    $_pasteCommand
    echo
}

_setClipboardCopyAndPasteCommands() {
    local _copyPasteError="Error: Cannot find native CLI copy/paste commands for platform [$OSTYPE].
    In order to copy/paste from the clipboard, \`xclip\` or \`xsel\` are required.
    Please run next command:
        sudo apt-get install xclip"
    local _printCopyPasteError='echo -e "$_copyPasteError" >&2'

    # Linux OS
    if [[ -n "$(os-version | grep -i 'linux')" ]]; then
        # `paste` is actually a handy tool to merge different files line-by-line
        # where resulting lines are the files' lines joined by <Tab>.
        # First, alias that to a more helpful name so it's not lost, then alias copy/paste.
        alias mergefiles='paste'

        # Try to use one of the third-party utils, or error if not installed.
        if isDefined 'xclip' &>/dev/null; then
            _copyCommand='xclip -sel clipboard'
            _pasteCommand='xclip -sel clipboard -o'
        elif isDefined 'xsel' &>/dev/null; then
            _copyCommand='xsel --clipboard -i'
            _pasteCommand='xsel --clipboard -0'
        else
            eval "$_printCopyPasteError"
        fi
    # Mac OS
    elif [[ -n "$(os-version | egrep -i '(darwin|mac|osx)')" ]]; then
        # Use built-in `pb` commands.
        _copyCommand='pbcopy'
        _pasteCommand='pbpaste'
    else
        eval "$_printCopyPasteError"
    fi
} && _setClipboardCopyAndPasteCommands



dirsize() {
    # ${FUNCNAME[0]} gets the name of this function, regardless of where it was called/defined
    usage="Displays total disk usages of all directories within the given path.

    Usage: ${FUNCNAME[0]} [-d=1] [-f] [path=./]

    Options:
        -d | Depth of directories to display; defaults to 1 (dirs inside <path>).
           | Total disk usages will be calculated regardless of -d value.
        -f | Include files in output."

    # local vars to avoid them being accessible outside this function
    local OPTIND=1 # bash is retarded and uses a *global* OPTIND, so it isn't reset on subsequent calls
    local depth=1
    local showFiles=false
    local path="."

    # "abc" == flags without an input following them, e.g. `-h` for --help
    # "a:"  == flags with an input following them, e.g. `-d 5`
    # ":ab" == leading colon activates silent mode, e.g. don't print `illegal option -- x`
    # TODO add way to parse `--long-arg[= ](value)?`
    #   Starter: https://stackoverflow.com/a/12523979/5771107
    #   Alternative:
    #       while [[ -n "$1" ]]; do <-- Don't use getopts since it doesn't support long args
    #           case "$1" in # <-- Read arg directly
    #               d | --depth) ... ;;
    #           esac
    #           shift # <-- Manually shift by one arg
    #       ...
    # TODO move to common function for use in all my functions, e.g.
    #   `local parsedArgs="`parseArgs "$@"`"`
    #   Will require calling `shift` to modify *parent*
    #       Or, could we just return "$@" from child? Not sure if it will maintain quotes or not
    while getopts "d:fh" opt; do
        # OPTIND = Arg index (equivalent to $1, $2, etc.)
        # OPTARG = Variable set to the flag (e.g. `-d myArgValue` makes OPTARG=myArgValue)
        # ${!OPTIND} = Actual flag (e.g. `-d myArgValue` makes ${!OPTIND}='-d')
        case "$opt" in
            d)
                depth="$OPTARG"
                ;;
            f)
                showFiles=true
                ;;
            *)
                # While nested functions are valid syntax in bash, we cannot create a
                # nested printUsage() function because it would be available outside the
                # scope of this function, and `local myFunc() {...}` is invalid syntax
                echo "$usage"
                return  # since this function is in a .profile, cannot use `exit` as that
                        # would exit the terminal session
                ;;
        esac
    done

    # ! (not) expression goes outside braces
    # -z is unary operator for length == 0
    # OPTIND gives the index of the next arg after getopts cycles through flags
    # Could instead do `shift "$((OPTIND - 1))"` to delete all args that getopts processed
    #   to allow for using $1 instead of ${!OPTIND}
    # ${x} == $x, gets arg at index `x`, e.g. $1
    # ${!x} is "indirection" - !x gets the value of x instead of its name, similar
    #   to JavaScript's `var x = 'hi'; return obj[x];` instead of `obj['x']`.
    if ! [[ -z "${!OPTIND}" ]]; then
        path="${!OPTIND}"
    fi

    if [ "$showFiles" = true ]; then
        echo -e "Directories:"
    fi

    # ls -lah has a max size display of 4.0K or 1G, so it doesn't show sizes bigger than that,
    # and doesn't tally up total size of nested directories.
    # du = disk usage
    #   -h human readable
    #   -d [--max-depth] of only this dir
    # sort -reverse -human-numeric-sort - sorts based on size number (taking into account
    #   human-readable sizes like KB, MB, GB, etc.) in descending order
    # Manually add '/' at the end of output to show they are directories
    du -h -d $depth "$path" | sort -rh | sed -E 's|(.)$|\1/|'

    if [ "$showFiles" = true ]; then
        # -e flag enables interpreting backslashes instead of printing them, e.g. \n
        echo -e "\nFiles:"

        # du can't mix -a (show files) and -d (depth) flags, so run it again for files
        find "$path" -maxdepth $depth -type f -print0 | xargs -0 du -h | sort -rh
    fi
}


memusage() {
    # `ps` = process status, gets information about a running process.
    # vsz = Virtual Memory Size: all memory the process can access, including shared memory and shared libraries.
    # rss = Resident Set Size: how much memory allocated to the process (both stack and heap), not including
    #       shared libraries, unless the process is actually using those libraries.
    # TL;DR, RSS is memory the process is using while VSZ is what the process could possibly use
    #
    # ps
    # | grep (column title line and search query)
    # | awk 'change columns 3 and higher to be in MB instead of KB'
    # | sed 'remove double-space from CPU column b/c not sure why it is there'
    ps x -eo pid,%cpu,user,command,vsz,rss | egrep -i "(RSS|$1)" | awk '{
        for (i=2; i<=NF; i++) {
            if ($i~/^[0-9]+$/) {
                $i=$i/1024 "MB";
            }
        }

        print
    }' | sed 's|  %CPU| %CPU|'
}



### Directory traversal ###

reposDir="`dirname "$dotfilesDir"`"  # use `dirname` instead of `realpath` to preserve symlinks/~ in path
repos() {
    # Path is relative to repositories directory.
    # Read all args via `$@` instead of `$1` in case spaces aren't escaped.
    #   `"$@"` collects all args into one string, even those separated by spaces (which would usually
    #   be split into separate lines internally by bash/function arg interpretation).
    local nestedPath="$@"
    # Note: Manually parsing strings via something like
    # absPath="`echo "$reposDir/$nestedPath" | tr '\n' ' ' | sed -E 's:([^\\]) (.):\1\\ \2:g'`"
    # to (1) replace newline-separated args, and (2) replace the now-one-line `my path/` with `my\ path/`
    # doesn't work/help/add anything new because bash double-quote strings automatically remove
    # backslashes (spaces don't need escaping in strings).
    local absPath="$reposDir/$nestedPath"

    cd "$absPath"
}
_autocompleteRepos() {
    local requestedRelativePath="${COMP_WORDS[@]:1}"
    local requestedAbsPath="$reposDir/$requestedRelativePath"

    # Note: `sed` seems to handle backslashes differently depending on where and how it's used.
    #   If on root-level, these work:
    #     echo "$var" | sed -E 's:\\ : :g'
    #     echo "$var" | sed -E "s:\\\ : :g"
    #   If nested inside another call, these work:
    #     newVar="`echo "$var" | sed -E 's:\\\ : :g'`"   # note the triple \ even in single-quotes
    #     newVar="$(echo "$var" | sed -E "s:\\\ : :g")"  # note the similarity to root-level, but requires $() instead of back-ticks
    #     (haven't tested for the double-quote inside back-ticks)

    # `find` is stupid and won't resolve escaped paths.
    # But at the same time, the suggestion autocomplete system will fail if the path isn't escaped
    # (see COMPREPLY note below).
    # Thus, unescape them only for `find` but otherwise leave them untouched.
    requestedAbsPath="`echo "$requestedAbsPath" | sed -E 's:\\\ : :g'`"

    # `find` will also fail if `$requestedAbsPath` doesn't exist, e.g. when the user presses <Tab> on
    # a partial directory name.
    # Thus, if the dir doesn't exist, then default to searching in the parent dir.
    if [[ -d "$requestedAbsPath" ]]; then
        local resolvedRelativePath="$requestedRelativePath"
        local resolvedAbsPath="$requestedAbsPath"
    else
        local resolvedRelativePath="`dirname "$requestedRelativePath"`"
        local resolvedAbsPath="`dirname "$requestedAbsPath"`"
    fi

    local dirOptions="`find -L "$resolvedAbsPath" -maxdepth 1 -type d`"  # -L follows symlinks. Necessary b/c we're searching `/repo/dir` and not `/repo/dir/`

    # Filter resulting directory options to include suggestions for only dirs that include the
    # string the user searched for.
    # Include partial dir names by using `$requestedAbsPath` instead of `$resolvedAbsPath`.
    # Note: Quote `$dirOptions` so that newlines are preserved.
    #   If it weren't quoted, all results would be on one line (`find` doesn't escape spaces in its
    #   results), causing any dirs that have spaces in their names to be impossible to parse separately.
    dirOptions="`echo "$dirOptions" | grep "$requestedAbsPath"`"

    # `sed "...d"` command is less user friendly than `s` in that to use any delimiter other
    # than `/`, it must be escaped.
    # e.g. `sed '/x/d'` --> `sed '\:x:d'`

    # Format dir options to be human readable.
    #   Remove the preceding repository-directory path.
    #   Remove any lines that are blank or only contain `/`.
    #   Replace double slashes with single slashes.
    #   Add a trailing slash to the end of dir options.
    dirOptions="`echo "$dirOptions" | sed -E "s:$reposDir/?::; \:^/?$:d; s://:/:; s:^/::; s:([^/])$:\1/:"`"

    if ! [[ -z "$requestedRelativePath" ]]; then
        # Remove the entry that is exactly the same as the path already prefilled in the shell
        dirOptions="`echo "$dirOptions" | egrep -v "$requestedRelativePath$"`"
    fi

    # Escape spaces in paths. See note above.
    dirOptions="$(echo "$dirOptions" | sed -E "s:([^\\]) (.):\1\\\ \2:g")"

    # Standard compgen logic, i.e.
    # `COMPREPLY=($(compgen -W "$dirOptions"))`
    # doesn't work when we manually escape strings because it takes the spaces out.
    # However, leaving unescaped spaces in causes the suggestions list to only autocomplete
    # the last word in the shell, resulting in a valid path's last word being replaced by
    # other random text (in our case, it's `find "$(dirname path)"` since we search the parent
    # if the child isn't found).
    # Thus, in order of causation:
    #   - The spaces have to be escaped
    #   - We can't use compgen
    #   - We generate our own word array
    #   - Word array needs to be split by newlines instead of spaces (done via IFS)
    # Note: Using quotes around paths was attempted, but that failed as well (also caused a worse
    # user experience b/c spaces being autocompleted in the shell wouldn't automatically be removed
    # when trying to go into a nested directory).
    local IFS=$'\n'
    COMPREPLY=($dirOptions)

    return 0
}
# TODO Look up `-X filterpat` for filename expansion
#   https://www.gnu.org/savannah-checkouts/gnu/bash/manual/bash.html#Programmable-Completion-Builtins
# `compopt` might help for removing nested directory prefixes

# Don't split options by space; split by newline instead b/c paths could include spaces in them.
# The easiest way to handle this would have been `-o filenames`, except that caused the issues above
# where the last word in a directory with spaces would be swapped out unexpectedly.
complete -F _autocompleteRepos -o nospace 'repos'

