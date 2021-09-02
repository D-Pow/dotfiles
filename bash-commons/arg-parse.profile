# When using Bash autocompletion (https://github.com/scop/bash-completion/blob/master/bash_completion)
# `COMP_WORDBREAKS` determines what delimiter separates "completion words" (i.e. `COMP_WORDS`, `COMP_CWORD`, etc.).
# By default, it includes colons, which is really inconvenient b/c colons aren't actually separating words!
# (This should be obvious b/c colons aren't included in `IFS`.)
# Thus, remove them here by changing the global variable, `COMP_WORDBREAKS`.
#
# Without changing this, autocompletion functions would require using a combination of both
# `_get_comp_words_by_ref` and `__ltrim_colon_completions`.
#
# e.g.
#
#   # `_get_comp_words_by_ref` is a function to customize the `COMP_WORDS` and `COMP_CWORD`
#   # generation. Specifically, it can let you change the delimiter between command word (`COMP_WORDS`)
#   # entries, get the current word directly without using array index reading, and auto-fill the
#   # `COMPREPLY` array.
#   #
#   # It is common to have colons be part of the command word
#   # e.g. `npmr build:prod` --> `('npmr' 'build' ':' 'prod')`
#   # So we want to cancel that out to keep colons in a single `COMP_WORDS` entry.
#   #
#   # It generates new variables, so use them instead of the original `COMP_WORDS`, `COMP_CWORD`, etc.
#   #
#   # Docs: https://github.com/scop/bash-completion/blob/master/bash_completion#L369
#   _get_comp_words_by_ref -n : -w commandWords -c currentWord -i commandWordIndex
#   declare commandsMatchingUserInput="$(echo "$availableCommands" | egrep "^$currentWord")"
#   COMPREPLY=($(compgen -W "$commandsMatchingUserInput" -- "$currentWord"))
#   # Trims off the portion of the currentWord left of the colon from all `COMPREPLY` entries.
#   # Required to use in conjunction with `_get_comp_words_by_ref` b/c otherwise, the `currentWord:`
#   # will be appended on top of `$currentWord` in the suggestions, breaking the whole system.
#   __ltrim_colon_completions "$currentWord"
#   return 0
#
# Note: `${variable//substring/replacement}` replaces all instances of `substring`.
COMP_WORDBREAKS=${COMP_WORDBREAKS//:}



parseArgs() {
    USAGE="parseArgs optionConfig \"\$@\"
    \`optionConfig\` is a specially-formatted associative array of options-to-variable names.

    optionConfig
    where shortOption=singleLetterOption, longOption=multiLetterOption
    and singleLetterOption entries use a single hyphen, multiLetterOption entries use two hyphens
    e.g.
        declare -A config=(
            ['shortOption|longOption,varToStoreValueIn']='Description of the option'
            ['shortOptionWithArg|longOptionWithArg:,varToStoreValueIn']='I require an argument, by space or = sign.'
            [':shortOptionIgnoreFailures|longOptionIgnoreFailures,varToStoreValueIn']='Eh, if they don't pass it or error otherwise, don't care'
        )

    Usage:
        parseArgs config \"\$@\"

    Returns:
        0/1 on success/failure.

    Sets:
        Variables as described by \`config\` (e.g. \`varToStoreValueIn\`).
        \`argsArray\`=(\"\$@\")

    Thus, specify the variables as you wish, and use \`argsArray\` to read all other arguments.

    Note:
        If an option has multiple entries (e.g. \`parseArgs config -a 'val1' --alpha 'val2'\`) then the args will
        be added to an array.
        Thus, \`config=(['a|alpha,arr'])\` will result in \`arr=('val1' 'val2')\`
    "

    declare -n _parentOptionConfig="$1" 2>/dev/null

    if array.empty _parentOptionConfig || [[ -z "$1" ]]; then
        echo -e "$USAGE"

        return 1
    fi

    shift


    declare -A getoptsParsingConfig=()
    declare getoptsStr=''

    if [[ -n "${_parentOptionConfig[':']+true}" ]]; then
        # Append colon to beginning if specified, silencing
        # all unrecognized flags and flags lacking args which require them.
        getoptsStr=':'

        # Remove from map since we want to iterate over it later
        unset _parentOptionConfig[':']
    fi

    for optConfigKey in "${!_parentOptionConfig[@]}"; do
        # Extract single-letter option name
        declare getoptsShort="$(echo "$optConfigKey" | sed -E 's/:?([^|:,]*).*/\1/')"
        # Extract multi-letter option name
        declare getoptsLong="$(echo "$optConfigKey" | sed -E 's/:?[^|:,]*\|?([^:,]*).*/\1/')"
        # Extract single-letter option name with surrounding left/right colon(s)
        declare getoptsEntry="$(echo "$optConfigKey" | sed -E 's/([^|,]*)\|?[^,:]*(:)?(,.*)/\1\2/')"
        # Extract variable name
        declare getoptsVariableName="$(echo "$optConfigKey" | sed -E 's/[^,]*,(.+)/\1/')"

        if [[ -n "$getoptsShort" ]]; then
            # Only add single-letter option name to the string passed to `getopts`
            getoptsStr+="$getoptsEntry"
        fi

        # Store short/long option matchers as keys in a map, and the variable as its value
        declare getoptsParsingConfigKey=

        if [[ -n "$getoptsShort" ]] && [[ -n "$getoptsLong" ]]; then
            getoptsParsingConfigKey="$getoptsShort|$getoptsLong"
        elif [[ -n "$getoptsShort" ]]; then
            getoptsParsingConfigKey="$getoptsShort"
        else
            getoptsParsingConfigKey="$getoptsLong"
        fi

        getoptsParsingConfig["$getoptsParsingConfigKey"]="$getoptsVariableName"
    done

    # Add ability to parse long options, which use `--optName`
    getoptsStr+='-:'


    declare OPTIND=1

    while getopts "$getoptsStr" opt; do
        if [[ "$opt" == "-" ]]; then
            # Handle long options with equal signs:
            # `--long-opt=MyValue`
            # From:
            #   $opt='-', $OPTARG='long-opt=MyValue'
            # To:
            #   $opt='long-opt', OPTARG='MyValue'
            #
            # Alternative would be to use '-' as an $opt switch-case entry, and
            # then parse the key/value there.
            # But doing it first has the benefit of grouping the short/long options
            # together in one block rather than duplicating the block for both short
            # and long options separately.
            #
            # Both require adding '-' in `getopts` string, e.g. `'-:'` if long option
            # accepts arguments.
            array.fromString -d '=' -r _longOptionArray "$OPTARG"
            array.slice -r _longOptionValArray _longOptionArray 1

            declare _longOptionKey="${_longOptionArray[0]}"
            declare _longOptionVal="$(array.join -s _longOptionValArray '=')"

            if [[ -z "$_longOptionVal" ]]; then
                # Handle long options with spaces:
                # `--long-opt MyValue` instead of `--long-opt=MyValue`
                # If `$_longOptionVal` is empty, then the long option as a ' ' rather than a '=' in it.
                # Thus, check if option config wants an argument for this; if so, manually add it.
                declare _parentOptionConfigKeys="${!_parentOptionConfig[@]}"

                if array.contains -e _parentOptionConfigKeys "$_longOptionKey:"; then
                    _longOptionVal="${!OPTIND}"
                    # Since this is a makeshift opt/arg reader, we have to manually shift over
                    # by one to get rid of the next option entry.
                    # i.e. `OPTIND == nextIndex+1`, so read that first, then get rid of the entry
                    # completely by calling `shift`
                    shift
                fi
            fi

            opt="$_longOptionKey"
            OPTARG="$_longOptionVal"
        fi

        if [[ "${OPTARG:0:1}" == "=" ]]; then
            # Regardless of using short/long options, any '=' in the OPTARG value
            # will persist, e.g.
            # `-f=val | --flag=val` --> `OPTARG='=val'`
            # So strip leading '=' in case that method was used
            OPTARG="${OPTARG:1}"
        fi


        for optKey in "${!getoptsParsingConfig[@]}"; do
            if [[ "$optKey" =~ "$opt" ]]; then
                declare -n getoptsVariable="${getoptsParsingConfig["$optKey"]}"

                if [[ -z "$getoptsVariable" ]]; then
                    if [[ -z "$OPTARG" ]]; then
                        # Option without argument
                        getoptsVariable=true
                    else
                        # Option with argument
                        getoptsVariable="$OPTARG"
                    fi
                else
                    # Multiple arguments for the same option have been supplied
                    # so convert/add to an array instead of string
                    getoptsVariable+=("$OPTARG")
                fi
            fi
        done
    done

    shift "$((OPTIND - 1))"

    declare -n remainingArgs="argsArray"
    remainingArgs=("$@")
}
