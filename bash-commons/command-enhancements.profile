# Make ** recursive, i.e. dir/**/*.txt will find all .txt files between
# /dir/(0-infinity subdirs)/*.txt instead of it only searching dir/(subdir)/*.txt
# See: https://unix.stackexchange.com/questions/49913/recursive-glob/49917#49917
shopt -s globstar
# Activate advanced glob patterns (often enabled by default but set it here just in case).
#   ?(pattern-list) - Matches zero or one occurrence of the given patterns.
#   *(pattern-list) - Matches zero or more occurrences of the given patterns.
#   +(pattern-list) - Matches one or more occurrences of the given patterns.
#   @(pattern-list) - Matches one of the given patterns.
#   !(pattern-list) - Matches anything except one of the given patterns.
# See: https://www.gnu.org/savannah-checkouts/gnu/bash/manual/bash.html#Pattern-Matching
shopt -s extglob
# Allow both uppercase and lowercase files/directories to be co-located together
# i.e. [ A.md, b.md, B.txt ] will retain that order instead of [ A.md, B.txt, b.md ]
shopt -u globasciiranges

# Jobs = Executions that are sent to the background, including running and paused processes.
# Apparently, `job` control isn't enabled by default (WTF???).
# This allows `(fg|bg) $jobId`, etc. job-related commands to work.`
# See: https://stackoverflow.com/questions/11821378/what-does-bashno-job-control-in-this-shell-mean/46829294#46829294
set -m

# Set SHELL environment to user's default shell.
# It doesn't always update even after calling `chsh -s /my/new/shell` so update it here.
# See: https://www.gnu.org/software/bash/manual/bash.html#index-SHELL
#
# Alternative: `ps -p $$ -o comm=`
# ProcessStatus -pID $thisShellPid -onlyKey comm[and]=[remove key prefix]
SHELL="$(which "$(echo "$0" | sed -E 's|^-||')")"

# Sort with dotfiles/directories listed before the rest.
# LC_COLLATE - Only affects collation (grouping), e.g. sorting upper/lower-case before/after each other.
# LANG - Language to use for output sorting, time/calendar/phone number/address formats, etc.
# LC_CTYPE - Defines the character set to use/recognize without affecting the language.
# LC_ALL - Overrides Everything.
#
# Setting it to `C` means "C-style character comparison" == symbols before uppercase before lowercase.
# This means dotfiles or those starting with symbols will come before numbers which come before letters.
#
# See:
#   http://teaching.idallen.org/net2003/06w/notes/character_sets.txt
#   https://superuser.com/questions/448291/how-can-i-make-ls-show-dotfiles-first
#   https://unix.stackexchange.com/questions/75341/specify-the-sort-order-with-lc-collate-so-lowercase-is-before-uppercase
#   https://stackoverflow.com/questions/30479607/explain-the-effects-of-export-lang-lc-ctype-and-lc-all
#   https://stackoverflow.com/questions/3222810/sorting-on-the-last-field-of-a-line/15677850#15677850
export LC_CTYPE='en_US.UTF-8' # Allow characters with diacritics to group with normal/non-diacritic chars
export LC_COLLATE='C.UTF-8' # Make symbols come before numbers before letters.


# TODO Increase the spacing between `lah` columns:
#   lah | egrep '^'
#   https://unix.stackexchange.com/questions/403099/formatting-ls-l-output-into-pipe-delimited-file
#   https://askubuntu.com/questions/272623/can-ls-l-be-made-to-separate-fields-with-tabs-rather-than-spaces-to-make-the-ou
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


isBeingSourced() {
    # Determines if the file is being called via `source script.sh` or `./script.sh`

    # Remove leading hyphen(s) from calling parent/this script file to account for e.g. $0 == '-bash' instead of 'bash'
    # Use `basename` to remove discrepancies in relative vs absolute paths
    declare callingSource="$(basename "$(echo "$0" | sed -E 's/^-*//')")"
    declare thisSource="$(basename "$(echo "$BASH_SOURCE" | sed -E 's/^-*//')")"

    [[ "$callingSource" != "$thisSource" ]]
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
    local _openCommand

    if isDefined xdg-open; then
        _openCommand=xdg-open
    elif isDefined gnome-open; then
        _openCommand=gnome-open
    else
        _openCommand=open
    fi

    _openCommand="$(which "$_openCommand")"

    $_openCommand "$@"
}


if ! isDefined readarray; then
    # `readarray == mapfile` but `readarray` wasn't introduced until Bash v4,
    # so define it here
    alias readarray='mapfile'
fi


_grepIgnoredDirs=('node_modules' '.git' '.idea' 'lcov-report')

alias grep="grep --exclude-dir={`array.join -s _grepIgnoredDirs ','`} --color=auto"

_egrepCommand=
_setEgrepCommand() {
    declare perlRegexSupported="$(echo 'true' | grep -P 'u' 2>/dev/null)"

    if [[ -n "$perlRegexSupported" ]]; then
        _egrepCommand='grep -P'
    else
        _egrepCommand='grep -E'
    fi
} && _setEgrepCommand
alias egrep=$_egrepCommand

gril() {
    local query="$1"

    shift

    # Globs are expanded before being passed into scripts/functions. So if the user passed
    # a glob pattern as the second arg, then using `$2` only gets the first match, regardless
    # of whether or not it's nested inside strings (e.g. `path=$2` or `path="$2"`).
    #
    # Thus, expand any possible glob patterns via "$@" (which gets all arguments passed to the function).
    # To ensure we only include files expanded from the glob, not the search query, store the
    # query first, then shift the arguments array by 1, then get all args remaining (which would be
    # the files matched by the glob pattern which was expanded before being passed to this script).
    local pathGlob="$@"

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
    # echo "Filter: ^(.(?!`array.join -s _grepIgnoredDirs '|'`))*$"
    # array.filter -er filteredPathGlob pathGlobArr "^(.(?!`array.join -s _grepIgnoredDirs '|'`))*$"
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


findIgnoreDirs() {
    # Net result (where [] represents what's added by the user):
    #   `find . -type d \( -name 'node_modules' -o -name '*est*' \) -prune -false -o` [-name '*.js']
    # See: https://stackoverflow.com/questions/4210042/how-to-exclude-a-directory-in-find-command/4210072#4210072
    local _findIgnoreDirs=()
    local OPTIND=1

    while getopts "i:" opt; do
        case "$opt" in
            i)
                _findIgnoreDirs+=("$OPTARG")
                ;;
        esac
    done

    shift $(( OPTIND - 1 ))

    local _findArgs=("$@")
    local _findToSearchIn="$1"
    local _findOpts
    array.slice -r _findOpts _findArgs 1

    local _findIgnoreDirsOptionName=' -o -name '
    local _findIgnoreDirsOption=''

    if ! array.empty _findIgnoreDirs; then
        # TODO: Try the simpler method here: https://stackoverflow.com/questions/4210042/how-to-exclude-a-directory-in-find-command/66794381#66794381

        # Note: Add single quotes around names in case they're using globs
        # e.g. Where injected strings are labeled with [], and array.join is labeled with ()
        # `-name '(first['][ -o -name ][']second)'
        _findIgnoreDirsOption="\( -name '`array.join -s _findIgnoreDirs "'$_findIgnoreDirsOptionName'"`' \)  -prune -false -o "
    fi

    # If called from another function which is forwarding globs surrounded by quotes,
    # then this function will receive duplicates of the quotes.
    #
    # e.g.
    # otherFunc() {
    #     local glob="$1"  # needs to be quoted, otherwise it will be expanded
    #     local opts="-i '$glob'"
    #     findIgnoreDirs -i "$1" to/search/ -name '*hello*'
    # }
    # otherFunc '*dir1*'
    # > findIgnoreDirs gets `-i ''*dir1*''`
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
    _findIgnoreDirsOption="$(echo "$_findIgnoreDirsOption" | sed -E "s|(['\"])\1|\1|g")"

    # Ignored dirs are already quoted, but still need to quote the search query
    local _findFinalCmd="find $_findToSearchIn $_findIgnoreDirsOption ${_findOpts[@]}"

    eval "$_findFinalCmd"
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
    # This can be fixed by using the `-C/--cd` option, which essentially runs `tar` in the specified
    # directory rather than the cwd, essentially the equivalent of `(cd /dir/to/compress && tar [options] .)`

    # Net result (where [] represents what's added by the user):
    #   tar [-czf with-spaces.tar.gz] -C ['../../dir/with spaces/dir[/file.ext]'] '.'

    local _tarArgs=("$@")
    local _tarOpts

    # Strip out desired dir from final `tar` command since we're `cd`ing into it (so it actually should be '.')
    array.slice -r _tarOpts _tarArgs 0 -1
    local _tarContainingDir="$(realpath "$(array.slice _tarArgs -1)")"  # `realpath` may or may not be necessary; goal was to remove `..` from the path passed to `tar -C [path]`
    local _tarToArchive='.'

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
