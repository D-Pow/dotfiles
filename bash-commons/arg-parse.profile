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



# STDIN Notes:
#
# To simultaneously read from stdin/output to stdout as lines come in (e.g. grep):
#   while read stdinLine; do
#       doWork stdinLine
#   done >&1
#
# To wait for them all to come in, and then read them all into an array:
#   readarray -t stdin



parseArgs() {
    USAGE="${FUNCNAME[0]} optionConfig \"\$@\"
    \`optionConfig\` is a specially-formatted associative array of options-to-variable names.

    \`optionConfig\` format:
        ([:singleLetterOption|multiLetterOption:,variableName]='Usage description')
        where each of the colons and option-entries are optional and multiLetterOption
        uses two hyphens.
        Colons function the same as the \`getopts\` string, i.e. \`getopts 'ab::c:'\`.

    Example:
        # Ensure all variables are declared as local variables to avoid them being made global
        declare var1
        declare var2
        declare var3
        declare -A optionConfig=(
            ['shortOption|longOption,var1']='Description of the option'
            ['shortOptionWithArg|longOptionWithArg:,var2']='I require an argument, by space or = sign.'
            [':shortOptionIgnoreFailures|longOptionIgnoreFailures,var3']='Eh, if they don't pass it or error otherwise, don't care'
            [':']= # Flag to set colon at beginning of getopts string, i.e. \`getopts ':abc'\`
            ['?']='String to pass to eval() upon unknown flag discovery. Defaults to \`echo -e \$USAGE; return 1;\`'
            ['USAGE']='Usage string without option descriptions (parseArgs will add those automatically)'
        )
        declare argsArray
        parseArgs optionConfig \"\$@\"

    Returns:
        0/1 on success/failure.

    Sets:
        Variables as described by \`config\` (e.g. \`var1\`).
        An array of the remaining args in the form of \`argsArray\`=(\"\$@\")

    Important:
        Declare your variables *BEFORE* calling parseArgs to ensure they're local to your
        calling function. Otherwise, variable values will persist between myFunc() calls.

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

    # Extract custom unknown-option and USAGE entries from parent config
    # so they aren't parsed into `getoptsParsingConfig`
    declare unknownFlagHandler="${_parentOptionConfig['?']}"
    unset _parentOptionConfig['?']
    declare parentUsageStr="${_parentOptionConfig['USAGE']}"
    unset _parentOptionConfig['USAGE']
    # Create new option-usage map for easier parent-usage printing.
    # Allows us to avoid nested for-loops later to match parsed-config keys to
    # parent-config descriptions.
    declare -A parentUsageOptions=()


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
        # Same logic for option-usage map, except with added hyphens.
        declare parentUsageOptionKey=

        if [[ -n "$getoptsShort" ]] && [[ -n "$getoptsLong" ]]; then
            getoptsParsingConfigKey="$getoptsShort|$getoptsLong"
            parentUsageOptionKey="-$getoptsShort|--$getoptsLong"
        elif [[ -n "$getoptsShort" ]]; then
            getoptsParsingConfigKey="$getoptsShort"
            parentUsageOptionKey="-$getoptsShort"
        else
            getoptsParsingConfigKey="$getoptsLong"
            parentUsageOptionKey="--$getoptsLong"
        fi

        # Store variable in internal config map to access when reading options
        getoptsParsingConfig["$getoptsParsingConfigKey"]="$getoptsVariableName"
        # Store description string in usage-config to access when printing parent's USAGE
        parentUsageOptions["$parentUsageOptionKey"]="${_parentOptionConfig["$optConfigKey"]}"
    done

    # Add ability to parse long options, which use `--optName`
    getoptsStr+='-:'

    # Add short/long options and their descriptions to parent's USAGE string
    # only if it's present.
    # Use keys from `getoptsParsingConfig` since it already parsed long/short
    # options, then get the description from the original parent config.
    if [[ -n "$parentUsageStr" ]]; then
        parentUsageStr+="\n\n    Options:\n"
        declare indentationAmount="        "

        for optionUsageKey in "${!parentUsageOptions[@]}"; do
            declare optionUsageDesc="${parentUsageOptions["$optionUsageKey"]}"
            # Use tab to separate key-value string for later `column` usage for auto-spacing columns
            declare optionUsageEntry="$indentationAmount$optionUsageKey\t| $optionUsageDesc\n"

            parentUsageStr+="$optionUsageEntry"
        done
    fi


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
            declare _longOptionArray
            declare _longOptionValArray
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


        declare optHandled=

        for optKey in "${!getoptsParsingConfig[@]}"; do
            if [[ "$optKey" =~ "$opt" ]]; then
                optHandled=true
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

        if [[ -z "$optHandled" ]]; then
            if [[ -n "$unknownFlagHandler" ]]; then
                eval "$unknownFlagHandler"
            else
                # `column` converts strings into tables.
                # For our usage, this makes the space between option keys and
                # descriptions evenly spaced so that all descriptions line up.
                # `-t` = Convert to table (i.e. make it evenly spaced)
                # `-c N` = Make N columns.
                # `-s delim` = Use specified string as a delimiter rather than all whitespace.
                #   Specify tab since spaces are used in description strings.
                echo -e "$parentUsageStr" | column -t -c 2 -s $'\t'

                return 1
            fi
        fi
    done

    shift "$((OPTIND - 1))"

    declare -n remainingArgs="argsArray"
    remainingArgs=("$@")
}
