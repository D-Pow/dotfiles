#!/usr/bin/env -S bash -e

# TODO For `npm run`, use `npm_lifecycle_event` for script name and `npm_lifecycle_script` for script content+args


getYarnArgs() {
    declare OPTIND=1
    declare keepCommandName=
    declare onlyCommandName=

    while getopts 'kc' opt; do
        case "$opt" in
            k)
                keepCommandName=true
                ;;
            c)
                onlyCommandName=true
                ;;
        esac
    done

    shift $(( OPTIND - 1 ))

    # When using Yarn, `npm_config_argv` takes the form of a JSON string, e.g.
    # '{"remain":[],"cooked":["add"],"original":["add","@nextdoor/blocks","next"]}'
    # We only care about the entries after the Yarn command, e.g. "@nextdoor/blocks" and "next"
    # To do so:
    #   - Get everything after "original"
    #   - Extract only the strings within the "original" array
    #   - Replace commas with spaces and remove quotes
    declare yarnArgs=($(
        echo $npm_config_argv \
            | grep -oE "\"original\": *\[.*\]" \
            | sed -E "s/.*\[(.*)\]/\1/; s/,/ /g; s/\"//g"
    ))
    declare yarnCommand="${yarnArgs[0]}"

    if [[ -n "$onlyCommandName" ]]; then
        echo "$yarnCommand"
        return
    fi

    if [[ -z "$keepCommandName" ]]; then
        # Remove the first arg, e.g. `add` in `yarn add`
        # Bash slice: ${arrayVals: startIndex: length}
        yarnArgs=("${yarnArgs[@]: 1: ${#yarnArgs[@]}}")
    fi

    declare i

    for i in "${!yarnArgs[@]}"; do
        declare arg="${yarnArgs[i]}"

        if [[ "$arg" =~ ^-.* ]]; then
            unset yarnArgs[i]
        fi
    done

    # Should actually be done via namerefs, i.e. `declare -n returnArray="$1"`
    # but those are only supported in GNU Bash v4.
    # Resort to echoing the entries, which doesn't preserve quotes, but that should be fine
    # for npm packages since they don't allow spaces anyway.
    echo ${yarnArgs[@]}
}

isBeingSourced() {
    # Determines if the file is being called via `source script.sh` or `./script.sh`

    # Remove leading hyphen(s) from calling parent/this script file to account for e.g. $0 == '-bash' instead of 'bash'
    # Use `basename` to remove discrepancies in relative vs absolute paths
    declare callingSource="$(basename "$(echo "$0" | sed -E 's/^-*//')")"
    declare thisSource="$(basename "$(echo "$BASH_SOURCE" | sed -E 's/^-*//')")"

    [[ "$callingSource" != "$thisSource" ]]
}

if ! isBeingSourced; then
    getYarnArgs "$@"
fi

# for var in $(compgen -v npm_); do echo "$var: ${!var}"; done
# Example from Yarn:
#   npm_config_argv: {"remain":[],"cooked":["add"],"original":["add","@nextdoor/blocks"]}
