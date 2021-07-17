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
    # Thus, expand it myself via "$@" (which gets all arguments passed to the function).
    # To ensure we only include files expanded from the glob, not the search query, store the
    # query first, then shift the arguments array by 1, then get all args remaining (which would be
    # the files matched by the glob pattern which was expanded before being passed to this script).
    local pathGlob="$@"

    if [ -z "$2" ]; then
        pathGlob=('.')
    fi

    egrep -ril "$query" $pathGlob
}

# `type` should be used instead; this is mostly meant as a reminder that it exists
alias define-func='type'
