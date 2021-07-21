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


alias ls='ls -Fh'
alias lah='ls -Flah'


alias grep='grep --exclude-dir={node_modules,.git,.idea,lcov-report} --color=auto'
alias egrep='grep -E'

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

    egrep -ril "$query" $pathGlob
}


# `type` should be used instead; this is mostly meant as a reminder that it exists
alias define-func='type'


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
    array.slice -r _findOpts _findArgs 1

    local _findIgnoreDirsOptionName=' -o -name '
    local _findIgnoreDirsOption=''

    if ! array.empty _findIgnoreDirs; then
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
