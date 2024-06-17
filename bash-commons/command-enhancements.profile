# TODO Increase the spacing between `lah` columns:
#   lah | egrep '^'
#   https://unix.stackexchange.com/questions/403099/formatting-ls-l-output-into-pipe-delimited-file
#   https://askubuntu.com/questions/272623/can-ls-l-be-made-to-separate-fields-with-tabs-rather-than-spaces-to-make-the-ou
#   https://unix.stackexchange.com/questions/288333/how-can-i-make-ls-show-dotfiles-first-while-staying-case-insensitive/361006#361006
#   https://unix.stackexchange.com/questions/10524/how-to-numerical-sort-by-last-column
#   https://superuser.com/questions/109537/how-to-sort-first-directories-then-files-etc-when-using-ls-in-unix
#   https://askubuntu.com/questions/525231/how-can-i-run-original-command-that-aliased-with-same-name
#
# -N | --literal = Don't add quotes to file/dir names
# -F | --classify = Show symbols for directories (/), executables (*), symlinks (->), pipes (|), etc. at the ends of file/dir names
# -h | --human-readable = Show sizes in Kilobytes, Megabytes, and Gigabytes
# -l = long output - permission bits, user, group, size, last-modified date/time, and the file/dir name
# -a = Show hidden files/dirs
# -A = -a except remove ./ and ../
alias ls='ls -NFh --color --group-directories-first' # Subsequent aliases inherit the default option flags from this alias
alias lah='ls -lA' # `-A` removes ./ and ../
alias lahh='lah -a' # Flags added later override those added earlier from previous aliases


alias printpath='echo $PATH | sed -E "s|:|\n|g"'


alias esed='sed -E'  # Note: -E is the same as -r, except undocumented since it's just for backward compatibility with BSD `sed`. Ref: https://stackoverflow.com/questions/3139126/whats-the-difference-between-sed-e-and-sed-e/3139925#3139925


isEven() {
    # Note: `(( x % 2 ))` is true if the number is even, but running a math command via `(( ... ))`
    # returns 1 if true instead of 0, which is the opposite of how the rest of Bash operates with
    # exit codes of 0 being true and non-zero is false.
    # Thus, negate it to make `isEven` return true if the number is even.
    ! (( "$1" % 2 ))
}


isDefined() {
    # Determines if the function or variable is defined
    # `type` could also work in place of `command`
    ( command -v "$1" || [[ -n "${!1}" ]] ) &>/dev/null

    # The existence-check must run in a subshell because if the variable has never been
    # declared, then bash will throw an `invalid variable name` error when it tries to access
    # the value of the variable. Throwing that error will cancel the calling parent's
    # execution. However, running it in a subshell means that only that subshell will exit,
    # allowing this/the calling parent functions to continue.
    # Thus, capture the exit code of the above subshell and return it.
    # 0 = true (defined), 1 = false (undefined)
    return "$?"
}


getFunctionCallStack() {
    declare USAGE="[-l|--line-numbers] [-c|--command] [-r|--return-array-name arrayName]
    Gets the file paths from the function call stack, starting from wherever this function was called up to the top-level parent.
    Optionally, also includes the functions called and/or the line number in the file where they're defined.

    Example:
        # script-1.sh
        #!/usr/bin/env -S bash
        source ./script-2.sh
        showFunctionCallStack() {
            printStuff
        }
        echo \"Output from \${BASH_SOURCE[0]}\"
        showFunctionCallStack


        # script-2.sh
        #!/usr/bin/env -S bash
        printStuff() {
            ${FUNCNAME[0]} -lc
        }
        echo \"Output from \${BASH_SOURCE[0]}\"
        printStuff


        # Terminal
        ./script-1.sh

        # Result
        Output from ./script-2.sh
        \"3 printStuff ./script-2.sh\"  \"6 source ./script-2.sh\"  \"2 main /abs/path/script-1.sh
        Output from /abs/path/script-1.sh\"
        \"3 printStuff ./script-2.sh\"  \"4 showFunctionCallStack /abs/path/script-1.sh\"  \"7 main /abs/path/script-1.sh
    "
    declare _callStackKeepLineNumber=
    declare _callStackKeepCommand=
    declare _retArrNameCallStack=()
    declare -A _callStackOptions=(
        ['c|command,_callStackKeepCommand']="Keep the base command used to run the file (doesn't include flags/args)."
        ['l|line-numbers,_callStackKeepLineNumber']="Keep file line numbers in the output."
        ['r|return-array-name:,_retArrNameCallStack']="Name of a (previously declared) array in which to store the results (default is printing to STDOUT)."
        ['USAGE']="$USAGE"
    )
    declare argsArray=

    parseArgs _callStackOptions "$@"
    (( $? )) && return 1


    declare _callStack=()
    declare _callerId=1  # Don't use 0 b/c that would include this function

    # `caller` is essentially equivalent to iterating through each of ${BASH_LINENO[@]}, ${FUNCNAME[@]}, and ${BASH_SOURCE[@]},
    # except it combines each into one simple call.
    # Inspiration:
    #   https://stackoverflow.com/questions/11090899/find-line-number-of-function-call-from-sourcing-file/11091255#11091255
    while caller $_callerId &>/dev/null; do
        declare _callStackEntry=($(caller $_callerId))
        declare _callStackLineNumber="${_callStackEntry[0]}"
        declare _callStackCommandWithoutArgs="${_callStackEntry[1]}"
        declare _callStackFile="$(array.slice _callStackEntry 2)"
        declare _callStackOutput=''

        (( _callerId++ ))

        if [[ -n "$_callStackKeepLineNumber" ]]; then
            _callStackOutput+="$_callStackLineNumber "
        fi

        if [[ -n "$_callStackKeepCommand" ]]; then
            _callStackOutput+="$_callStackCommandWithoutArgs "
        fi

        _callStackOutput+="$_callStackFile"

        _callStack+=("$_callStackOutput")
    done

    if [[ -n "$_retArrNameCallStack" ]]; then
        declare -n _retArrCallStack="$_retArrNameCallStack"
        _retArrCallStack=("${_callStack[@]}")
    else
        echo "${_callStack[@]}"
    fi
}


isInteractiveShell() {
    # Determines if the current environment that called this function is interactive,
    # i.e. controlling a user's terminal's STDIN/STDOUT/STDERR.
    #
    # `$-` contains the options of the shell before it executes anything else (e.g. .bashrc, .profile, etc.).
    # If `i` exists in it, then the shell is interactive, i.e. not a script, system process, etc.
    #
    # Refs:
    #   `$-` = https://stackoverflow.com/a/42757277/5771107
    #   TTY vs shell vs terminal = https://unix.stackexchange.com/questions/4126/what-is-the-exact-difference-between-a-terminal-a-shell-a-tty-and-a-con
    #   Checking if interactive/login shell = https://unix.stackexchange.com/questions/26676/how-to-check-if-a-shell-is-login-interactive-batch/26782#26782
    [[ "${-//i/_}" != "$-" ]]
}


isBeingSourced() {
    declare USAGE="[-s|--shell] [filePath]
    Determines if the file is being sourced (i.e. called via \`source script.sh\` instead of \`./script.sh\`).
    Optionally, checks the specified file instead of the file in which this function was called.


    Example:
        # Mimic the behavior of \`main()\` functions (e.g. \`if __name__ == '__main__'\` in Python).
        if ! ${FUNCNAME[0]} \"\$BASH_SOURCE[0]\"; then
            mainFunc \"\$@\"
        fi
    "
    declare _shellOnly=
    declare -A _isBeingSourcedOptions=(
        ['s|shell,_shellOnly']='Restricts sourcing-parent validations to only check if the top-level (interactive/login) shell is sourcing the file.'
        ['USAGE']="$USAGE"
    )
    declare argsArray=

    parseArgs _isBeingSourcedOptions "$@"
    (( $? )) && return 1


    # If no file is specified, then default to the file where this function was called.
    # Attempt to get it from the function call stack since it's the most reliable method.
    # and fallback to the last file on the call stack.
    declare _functionCallStack=()
    getFunctionCallStack -r _functionCallStack
    declare _fileMaybeBeingSourcedDefault="${_functionCallStack[0]}"


    # Fallback to the last file on the call stack if the function call stack failed.
    #
    # `BASH_SOURCE` is an array of the file `source` stack just like `FUNCNAME` is an array of
    # the function call stack. For example:
    #   ${BASH_SOURCE[0]}  =  This file.
    #   ${BASH_SOURCE[1]}  =  The process or file parent that directly sourced this file.
    #   ${BASH_SOURCE[ ${#BASH_SOURCE[@]} - 1 ]}  =  The top-level file if sourced from a script
    #       that was run; this file's relative path if sourced from the shell process itself, including
    #       the case where shell sourced a file that sourced this file.
    #   $0  =  Top-level parent process/shell (if this file were sourced from an interactive shell,
    #       takes the format `-shellName`)
    #       or file (if a script were run that sourced this file, either directly or transiently through other files).
    # Ref: https://unix.stackexchange.com/questions/4650/determining-path-to-sourced-shell-script/153061#153061
    _fileMaybeBeingSourcedDefault="${_fileMaybeBeingSourcedDefault:-${BASH_SOURCE[ ${#BASH_SOURCE[@]} - 1 ]}}"


    # Compare `$0` (top-level parent, whether file or interactive shell) with either the file specified as an arg
    # or the (attempted) file in which the function was called.
    # `$1` allows a "relative" parent to be defined so that the file calling this function can be explicitly
    # specified, which ensures this function to work as expected (it's not an alias, so keywords like `BASH_SOURCE`
    # are defined relative to this function's physical location).
    # It also allows for custom source-checking functionality, i.e. checking if a specific file is being sourced.
    #
    # Note that we have to remove any leading hyphen(s) from the parents to account for interactive login shells,
    # e.g. `$0 == -bash` instead of `bash`.
    #
    # Also, normalize paths to remove relative/absolute path discrepancies.
    # Note: We have to use the same combination of `realpath`, `basename`, `dirname`, etc. to resolve both variables,
    # they can't use different logic.
    # Primary example is Mac: When using Brew's GNU Bash version >3, the paths resolve in the manner below due to
    # symlinks - but using `realpath` always gets the absolute path.
    #     $0  ->  bash
    #     which  ->  /usr/local/bin/bash
    #     realpath  ->  /usr/local/Cellar/bash/5.1.12/bin/bash
    #     basename  ->  bash
    declare _fileMaybeBeingSourced="${argsArray[0]:-$_fileMaybeBeingSourcedDefault}"
    declare _relativeCallingParent="$(realpath "$(echo "$_fileMaybeBeingSourced" | sed -E 's/^-*//')")"
    declare _topLevelCallingParent="$(realpath "$(which "$(echo "$0" | sed -E 's/^-*//')")")"
    declare _shellParent="$(realpath "$(which "$SHELL")")"


    if [[ -n "$_shellOnly" ]]; then
        # Avoid issues with shebangs by only checking against interactive login shells

        declare _isInteractiveShell="$(
            isInteractiveShell \
                && echo 1 \
                || echo 0
        )"

        # A shebang of e.g. `#!/usr/bin/env bash -l` will act as a login shell, so it sources the respective `$HOME/.profile`
        # file rather than `$HOME/.bashrc`.
        # However, it won't necessarily be interactive, e.g. a script that requires system setup from a user's .profile but isn't
        # meant to take control of their terminal.
        # If the top-level parent is the same as the active shell environment, then it's likely either a login shebang
        # or an interactive shell.
        declare _isLoginShell="$(
            isLoginShell || [[ "$_topLevelCallingParent" == "$_shellParent" ]] \
                && echo 1 \
                || echo 0
        )"

        declare _isInteractiveLoginShell=$(( $_isLoginShell + $_isInteractiveShell == 2 ))

        (( $_isInteractiveLoginShell ))
    else
        [[ "$_topLevelCallingParent" != "$_relativeCallingParent" ]]
    fi
}


open() {
    # Automatically selects the correct, user-friendly terminal command to open
    # files/directories/URLs using the OS' default application.
    # Will work on both Linux (theoretically any distro) and the garbage that is Mac.
    #
    # Also very useful to copy into standalone scripts because scripts are run in
    # subshells, which means they may or may not `source ~/.profile`. This means
    # that any rewrites of commands, e.g. `alias open='xdg-open'`, are not necessarily
    # applied, so this function can be copied there for cross-platform compatibility.
    declare _openCommand

    if isDefined xdg-open; then
        _openCommand=xdg-open
    elif isDefined gnome-open; then
        _openCommand=gnome-open
    elif os-version | grep -iq MINGW; then
        _openCommand=start
    elif isWsl; then
        _openCommand='cmd start'
    else
        _openCommand=open
    fi

    _openCommand="$(which "$_openCommand" || echo "$_openCommand")"

    $_openCommand "$@"
}


if ! isDefined readarray; then
    # `readarray == mapfile` but `readarray` wasn't introduced until Bash v4,
    # so define it here
    alias readarray='mapfile'
fi


_grepIgnoredDirs=('node_modules' '.git' '.idea' 'lcov-report')

alias grep="grep --exclude-dir={`array.join _grepIgnoredDirs ','`} --color=auto"

if [[ "$(type -t egrep)" == 'alias' ]]; then
    unalias egrep
fi

egrep() {
    declare _egrepCommandFlag='-P'
    declare perlRegexSupported="$(echo 'true' | grep -P 'u' 2>/dev/null)"

    if [[ -z "$perlRegexSupported" ]]; then
        _egrepCommandFlag='-E'
    fi

    grep $_egrepCommandFlag "$@"
}

alias eegrep='$(which egrep)'

gril() {
    declare query="$1"

    shift

    # Globs are expanded before being passed into scripts/functions. So if the user passed
    # a glob pattern as the second arg, then using `$2` only gets the first match, regardless
    # of whether or not it's nested inside strings (e.g. `path=$2` or `path="$2"`).
    #
    # Thus, expand any possible glob patterns via "$@" (which gets all arguments passed to the function).
    # To ensure we only include files expanded from the glob, not the search query, store the
    # query first, then shift the arguments array by 1, then get all args remaining (which would be
    # the files matched by the glob pattern which was expanded before being passed to this script).
    declare pathGlob="$@"

    if [[ -z "$pathGlob" ]]; then
        pathGlob=('.')
    fi

    # TODO `gril` fails when glob has too many files, e.g. when searching dir/**/*.js in JS project
    # that has node_modules folder.
    # Error: Argument list too long.
    #
    # local pathGlobArr=("$@")
    # array.toString pathGlobArr
    # echo "${@:2:1}"
    # echo "Filter: ^(.(?!`array.join _grepIgnoredDirs '|'`))*$"
    # array.filter -er filteredPathGlob pathGlobArr "^(.(?!`array.join _grepIgnoredDirs '|'`))*$"
    # array.toString filteredPathGlob
    #
    # Problem is that both quoting and not quoting results in problems:
    #   arr=('../dotfile/Programs/Sublime/Data/Packages/Babel Snippets/README.md' '../dotfile/Programs/Sublime/Data/Packages/Babel/README.md' '../dotfile/Programs/Sublime/Data/Packages/Babel/node_modules/get-stdin/readme.md' '../dotfile/Programs/Sublime/Data/Packages/HTML-CSS-JS Prettify/README.md')
    #   # length == 4, filtering out node_modules should result in 3
    #   res=($(printf '%s\n' "${arr[@]}" | egrep '^(.(?!node_modules))*$')) && array.toString res
    #   # length == 5, not 3!
    #   res=("$(printf '%s\n' "${arr[@]}" | egrep '^(.(?!node_modules))*$')") && array.toString res
    #   # length == 1, not 3!

    # egrep -ril "$query" "${filteredPathGlob[@]}" 2>/dev/null
    egrep -ril "$query" $pathGlob

    # Tests:
    # source ../dotfile/.profile mac_Nextdoor && gril asdfqwer ../dotfile/**/*.txt
    # source ../dotfile/.profile mac_Nextdoor && gril mock react-app-boilerplate/**/*.js
}


modifyFileLinesInPlace() {
    declare USAGE="${FUNCNAME[0]} [-n] <sed-regex-command> <file>
    Modifies all lines in a file according to the \`sed\` command regex string.

    Options:
        -n  |   Truncate all additional, sequential newlines into a single newline.
        -e  |   Erase all empty lines.
        -b  |   Erase empty lines only at the beginning of the file (implies \`-e\`).
    "

    declare _truncateNewlines=
    declare _eraseEmptyLines=
    declare _eraseEmptyLinesOnlyAtBeginning=
    declare OPTIND=1

    while getopts ':neb' opt; do
        case "$opt" in
            n)
                _truncateNewlines=true
                ;;
            e)
                _eraseEmptyLines=true
                ;;
            b)
                _eraseEmptyLines=true
                _eraseEmptyLinesOnlyAtBeginning=true
                ;;
            *)
                echo -e "$USAGE" >&2
                return 1
                ;;
        esac
    done

    shift $(( OPTIND - 1 ))

    if [[ -z "$1" ]] || [[ -z "$2" ]]; then
        echo -e "$USAGE" >&2
        return 1
    fi

    declare sedRegexCommand="$1"
    declare fileToModify="$2"
    declare fileToModifyBackupName="$fileToModify.bak"
    declare modifiedFileContents="$(sed -E "$sedRegexCommand" "$fileToModify")"

    if [[ -n "$_truncateNewlines" ]]; then
        # `tr -s|--squeeze-repeats` = Replace duplicate occurrences of the specified character with one occurrence
        modifiedFileContents="$(echo "$modifiedFileContents" | tr -s '\n')"
    fi

    if [[ -n "$_eraseEmptyLines" ]]; then
        if [[ -z "$_eraseEmptyLinesOnlyAtBeginning" ]]; then
            # Default `awk` command is `print $0` where `$0` is the whole line
            # Print only non-empty lines
            modifiedFileContents="$(echo -e "$modifiedFileContents" | awk '!/^$/')"
        else
            modifiedFileContents="$(echo -e "$modifiedFileContents" | awk '{
                if (NR == 1) {
                    # If the first line, set `found` to false since we have not found a non-empty line yet
                    found = 0
                }

                if (/^$/ && !found) {
                    # Do not print the line since it is empty
                } else {
                    # We found a non-empty line, so print all future empty lines
                    found = 1

                    print $0
                }
            }')"
        fi
    fi

    if [[ -n "$modifiedFileContents" ]]; then
        echo "$modifiedFileContents" > "$fileToModify"
    else
        # No other lines left, so just truncate the file
        # `:` = no-op (do nothing silently)
        # We can't use `echo` because if the resulting string is empty, then it becomes `echo '' > file` which adds a newline to the file
        : > "$fileToModify"
    fi
}


findRegex() {
    # Sets the default type of regex to `posix-extended` to get as close as possible to
    # high-level languages' regex engines vs Bash's old-fashioned one (which doesn't
    # support e.g. `\s` without configuring it in the command specifically).
    #
    # Still requires passing either `-(i)name` or `-(i)regex` since the search query
    # is an arg of those flags, and thus must be directly after them.
    # e.g. `find /path -regextype posix-extended -regex -maxdepth 2 searchQuery` would fail.
    #
    # See:
    #   - https://stackoverflow.com/questions/5249779/how-to-search-filenames-by-regex-with-find/5249797#5249797
    declare _findDirToSearch="$1"

    shift

    find "$_findDirToSearch" -regextype posix-extended "$@"
}


findIgnore() {
    declare USAGE="[OPTIONS...] [PATH] [\`find\` OPTIONS...]
    Calls \`find\`, ignoring the specified directories or files.
    "
    # Net result (where [] represents what's added by the user):
    #   `find . -type d \( -name 'node_modules' -o -name '*est*' \) -prune -false -o` [-name '*.js']
    # See: https://stackoverflow.com/questions/4210042/how-to-exclude-a-directory-in-find-command/4210072#4210072
    #
    # Alternative: Use `! -(i)?(name|wholename|path) <path>`
    declare _findIgnorePaths=()
    declare _findToSearchIn=
    declare argsArray
    declare -A _findIgnoreOptions=(
        ['i|ignore:,_findIgnorePaths']="Path to ignore; Use glob-stars for nested directories/files."
        ['p|search-dir:,_findToSearchIn']="Path in which to run \`find\`; Useful in place of positional arg for path if wanting to forward an array of args from a parent function to ${FUNCNAME[0]} in a simple way instead of manually finding the path and reordering the array before calling ${FUNCNAME[0]}."
        [':']=
        ['?']=
        ['USAGE']="$USAGE"
    )

    parseArgs _findIgnoreOptions "$@"
    (( $? )) && return 1

    declare _findOpts=("${argsArray[@]}")

    if [[ -z "$_findToSearchIn" ]] && [[ -d "${argsArray[0]}" ]]; then
        # If the dir to search through with `find` was passed as positional arg 1,
        # then pop it out from the positional args
        _findToSearchIn="${argsArray[0]}"
        _findOpts=()

        array.slice -r _findOpts argsArray 1
    fi

    declare _findIgnoreOption=''

    if ! array.empty _findIgnorePaths; then
        # TODO: Try the simpler method here: https://stackoverflow.com/questions/4210042/how-to-exclude-a-directory-in-find-command/66794381#66794381

        # Note: Add single quotes around names in case they're using globs
        # e.g. Where injected strings are labeled with [], and array.join is labeled with ()
        # `-name '(first['][ -o -name ][']second)'
        #
        # Original implementation:
        # _findIgnoreOption="\( -name '`array.join _findIgnorePaths "' -o -name '"`' \) -prune -false -o "

        # `-path` is more resilient to glob-stars than `-name`.
        # `!` is more resilient to directories than `\( -name "$dir" \) -prune -false -o`.
        _findIgnoreOption="! -ipath '$(array.join _findIgnorePaths "' ! -ipath '")'"
    fi

    # If called from another function which is forwarding globs surrounded by quotes,
    # then this function will receive duplicates of the quotes.
    #
    # e.g.
    # otherFunc() {
    #     local glob="$1"  # needs to be quoted, otherwise it will be expanded
    #     local opts="-i '$glob'"
    #     findIgnore -i "$1" to/search/ -name '*hello*'
    # }
    # otherFunc '*dir1*'
    # > findIgnore gets `-i ''*dir1*''`
    #
    # This cannot be avoided b/c if the parent function doesn't wrap globs in quotes, then
    # it will be expanded and unusable by this function (causes duplicate quotes).
    # If args are not quoted in this function, then any user-level globs in the live shell
    # will be expanded upon function call (i.e. no quotes are added and it's expanded).
    # So, if we remove our quotes in this function, we'll ruin live shell usage.
    # If we keep them, then we'll ruin usability for other functions calling this.
    #
    # Thus, remove all instances of duplicate quotes AFTER the array.join is called
    # so that any duplicates from either the parent's quotes or our internal quotes are removed.
    _findIgnoreOption="$(echo "$_findIgnoreOption" | sed -E "s|(['\"])\1|\1|g")"

    # Ignored dirs are already quoted, but still need to quote the search query
    declare _findFinalCmd="find $_findToSearchIn $_findIgnoreOption ${_findOpts[@]}"

    # Silence the annoying warnings about '`-maxdepth` is a global option that needs to be before other options'
    # since it's not easily removed during arg-parsing without extra complex logic
    eval "$_findFinalCmd" 2> >(awk '{ if (! /.*find: warning:/) { print($0); } }')
}


tarremovepathprefix() {
    # `tar` generates archive-file directory structure based on the current working directory rather
    # than that of the directory being compressed/archived. This results in the archive files being
    # unnecessarily nested in directories they (most of the time) shouldn't be, i.e.
    #
    # tree /dir/to/compress
    #   |-- /nested/with/many/files
    #   |-- a.file
    #   |-- b.file
    # cd /dir/to/output/into
    # tar czf my-archive.tar.gz ../../compress
    # tar -tf my-archive.tar.gz
    #   |-- ../../compress//nested/with/many/files
    #   |-- ../../compress/a.file
    #   |-- ../../compress/b.file
    #
    # This can be fixed by using the `-C/--cd` option, which will run `tar` in the specified directory
    # rather than the cwd, essentially the equivalent of `(cd /dir/to/compress && tar [options] .)`

    # Net result (where [] represents what's added by the user):
    #   tar [-czf with-spaces.tar.gz] -C ['../../dir/with spaces/dir[/file.ext]'] '.'

    declare _tarArgs=("$@")
    declare _tarOpts

    # Strip out desired dir from final `tar` command since we're `cd`ing into it (so it actually should be '.')
    array.slice -r _tarOpts _tarArgs 0 -1
    declare _tarContainingDir="$(realpath "$(array.slice _tarArgs -1)")"  # `realpath` may or may not be necessary; goal was to remove `..` from the path passed to `tar -C [path]`
    declare _tarToArchive='.'

    if [[ -f "${_tarContainingDir}" ]]; then
        # User passed in a file instead of a directory.

        # First, get the file name so we don't archive the entire directory's contents.
        _tarToArchive="$(basename "$_tarContainingDir")"

        # Second, `cd` into the dir containing the file.
        # This removes the preceding path-to-dir prefix from the archived files' names.
        _tarContainingDir="$(dirname "$_tarContainingDir")"
    fi

    tar "${_tarOpts[@]}" -C "$_tarContainingDir" "$_tarToArchive"
}


if ! isDefined tree; then
    # `tree` isn't defined, so define it here
    declare _treeUsage="${FUNCNAME[0]} [OPTIONS...] [path]
    Manual re-implementation of GNU \`tree\` (https://linux.die.net/man/1/tree) with some minor modifications.

    Options:
        -i | Ignore directory during traversal.
        -d | Limit to \`d\` levels deep.
    "

    tree() {
        declare _treeIgnoreDirs=()
        declare _treeDepth=
        declare OPTIND=1

        while getopts "i:d:" opt; do
            case "$opt" in
                i)
                    _treeIgnoreDirs+=("$OPTARG")
                    ;;
                d)
                    _treeDepth="$OPTARG"
                    ;;
                *)
                    echo -e "$_treeUsage" >&2
                    return 1
                    ;;
            esac
        done

        shift $(( OPTIND - 1 ))

        declare _pathsToDisplayArgs=("$@")

        if array.empty _pathsToDisplayArgs; then
            _pathsToDisplayArgs=('.')
        fi

        declare origIFS="$IFS"
        declare IFS=$'\n'

        declare _pathsToDisplay=()
        declare _pathToDisplay=
        for _pathToDisplay in "${_pathsToDisplayArgs[@]}"; do
            # Convert all supplied paths to absolute paths for better resolution
            _pathsToDisplay+=("$(abspath "$_pathToDisplay" | trim)")
        done

        IFS="$origIFS"

        declare _treeDepthFindOpts="${_treeDepth:+-maxdepth $_treeDepth}"
        declare _treeIgnoreDirsFindOpts=''

        if ! array.empty _treeIgnoreDirs; then
            # Add single quotes around names in case they're using globs, like `findIgnore()` does.
            # e.g. Where injected strings are labeled with [], and array.join is labeled with ()
            # `-i '(first['][ -i ][']second)'
            _treeIgnoreDirsFindOpts="-i '`array.join _treeIgnoreDirs "' -i '"`'"
        fi

        declare _numPathsToDisplay="$(array.length _pathsToDisplay)"

        if (( $_numPathsToDisplay > 1 )); then
            for _pathToDisplay in "${_pathsToDisplay[@]}"; do
                tree $_treeIgnoreDirsFindOpts ${_treeDepth:+-d $_treeDepth} "$_pathToDisplay"

                if [[ "$_pathToDisplay" != "${_pathsToDisplay[$(( _numPathsToDisplay - 1)) ]}" ]]; then
                    echo  # Add extra spacing between path entries
                fi
            done

            return
        fi

        # `cd` into the directory to avoid extra slashes/nested `| ` text from appearing
        #   e.g. `tree ../dir/` would result in `find ../dir/` being called and resulting file/dir entries
        #   being printed as `../dir/file.txt` --> `| ├─file.txt` instead of `├─file.txt`
        # `find` doesn't add a trailing slash on directories by default, so add them manually via `printf`
        declare allEntriesWithTrailingSlashOnDirsDirs="$(
            cd "$_pathsToDisplay"
            findIgnore $_treeIgnoreDirsFindOpts . $_treeDepthFindOpts -type d -exec sh -c "'printf \"\$0/\n\"'" {} '\;' -or -print 2>/dev/null
        )"
        # Remove duplicate `//` when runing `tree someDir/` (no double slashes with `tree someDir`)
        declare normalizedPaths="`echo "$allEntriesWithTrailingSlashOnDirsDirs" | sed -E "s#//#/#g"`"
        # Replace preceding `path/to/` in `path/to/file.txt` with `| | ├─file.txt` to match standard `tree path/` output.
        # sed -rEgex 'command-1; command-2'
        # command-1: Replace `some-text/` with `| ` repeatedly for however many nested parent dirs exist for the file.
        #   e.g. `dir1/dir2/file.txt` --> `| | file.txt`
        #   However, if the line ends with `/`, then don't replace the final trailing `/` since that entry is a directory.
        # command-2: Replace the final `| ` from the previous `| | file.txt` output with `├─` to show it's a file within that directory.
        #   e.g. `| | file.txt` --> `| ├─file.txt`
        declare parentDirsReplacedWithTreeDelimiters="`echo "$normalizedPaths" | sed -E 's#[^/]*/([^/]*/$)?#| \1#g; s#\| ([^|])#├─\1#g'`"
        # Replace first line of output with the user-specified path since it's erased in the sed commands above
        declare firstLineReplacedWithParentPath="`echo "$parentDirsReplacedWithTreeDelimiters" | sed -E "1 s|^.*$|$_pathToDisplay|"`"

        echo "$firstLineReplacedWithParentPath"
    }
fi



mvnProjectVersion() {
    mvn \
        --non-recursive \
        -Dexec.executable=$(if isWindows || isWsl; then echo 'cmd'; else echo 'bash'; fi) \
        -Dexec.args='/C echo ${project.version}' 'org.codehaus.mojo:exec-maven-plugin:1.3.1:exec' \
        -q
}
