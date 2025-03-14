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
#   return
#
# Note: `${variable//substring/replacement}` replaces all instances of `substring`.
COMP_WORDBREAKS=${COMP_WORDBREAKS//:}



parseArgs() {
    declare USAGE="${FUNCNAME[0]} optionsConfig \"\$@\"
    \`optionsConfig\` is a specially-formatted associative array of optionFlag-to-variable names.

    \`optionsConfig\` format:
        ([:singleLetterOption|multiLetterOption:,variableName]='Usage description')
        where each of the colons and option-entries are optional and multiLetterOption
        uses two hyphens.
        Colons function the same as the \`getopts\` string, i.e. \`getopts 'ab::c:'\`.

    Example:
        # Ensure all variables are declared as local variables to avoid them being made global
        declare var1
        declare var2
        declare var3
        declare argsArray
        declare stdin
        declare -A optionsConfig=(
            ['shortOption|longOption,var1']='Description of the option'
            ['shortOptionWithArg|longOptionWithArg:,var2']='I require an argument, by space or = sign.'
            [':shortOptionIgnoreFailures|longOptionIgnoreFailures,var3']='Eh, if they don't pass it or error otherwise, don't care'
            [':']= # Flag to set colon at beginning of getopts string, i.e. \`getopts ':abc'\`
            ['?']='String to pass to \`eval\` upon unknown flag discovery.'
                   # Defaults to \`echo -e \"\$USAGE\"; return 1;\`.
                   #
                   # Set the key to \`break\` to stop parsing at the first unknown flag, merging it and all
                   # following flags/args (regardless of whether or not they're known) into \`argsArray\`.
                   #
                   # Set the key but leave it blank (i.e. \`['?']=\`) to step over unknown flags if encountered
                   # and continue trying to parse known flags that might exist after unknown ones.
                   # All unknown flags and their values will still be placed in \`argsArray\` like they are
                   # with \`break\`.
                   #
                   # These are useful for e.g. forwarding flags to underlying scripts/functions without
                   # duplicating all those flags in their own USAGE docs.
            ['USAGE']='Usage string without \${FUNCNAME[0]} or option flag descriptions.'
                       # \`${FUNCNAME[0]}\` will automatically prepend the calling parent function name at the beginning of the
                       # specified ['USAGE'] string and append auto-spaced option flags/descriptions at the end.
        )
        ${FUNCNAME[0]} optionsConfig \"\$@\"
        # To exit your function if \`${FUNCNAME[0]}\` fails, add the line below (\`USAGE\` will be printed by default).
        (( \$? )) && return 1    # Alternatively: [[ \$? -ne 0 ]]
        #
        # Note:
        # True(0)/False(1) are reversed in arithmetic expressions -- (( 1 )) == True, (( 0 )) == False
        # so use \`&&\` instead of \`||\`.
        # Also: \`\$?\` corresponds only to the single, immediately preceding command, so it can't be accessed twice.
        # If you need to use \`\$?\` multiple times, set it in a variable directly after calling \`${FUNCNAME[0]}\`,
        # e.g. \`declare _parseArgsRetVal=\"\$?\"\`

    Options:
        -c  |   Allow reading options placed after positional args.
        -i  |   Don't capture/read from STDIN.

    Returns:
        0/1 on success/failure.

    Sets:
        Variables as described by \`config\` (e.g. \`var1\`).
        An array of the remaining args in the form of \`argsArray=(\"\$@\")\`.
        An array of STDIN inputs (not interactive/live) in the form of \`readarray -t stdin\`.

    Important:
        Declare your variables *BEFORE* calling ${FUNCNAME[0]} to ensure they're local to your
        calling function. Otherwise, variable values will persist between myFunc() calls.

    Thus, specify the variables as you wish, and use \`argsArray\` to read all other arguments.

    Note:
        If an option has multiple entries (e.g. \`${FUNCNAME[0]} config -a 'val1' --alpha 'val2'\`) then the args will
        be added to an array.
        Thus, \`config=(['a|alpha,arr'])\` will result in \`arr=('val1' 'val2')\`
    "

    # Custom options for `parseArgs()` itself
    declare _allowOptsAfterArgs=
    declare _parseStdin=true

    declare opt=
    declare OPTIND=1
    # "abc" == flags without an input following them, e.g. `-h` for --help
    # "a:"  == flags with an input following them, e.g. `-a 5`
    # ":ab" == leading colon activates silent mode, e.g. don't print `illegal option -- x`
    #
    # Alternatives for parsing long option flags: https://stackoverflow.com/questions/402377/using-getopts-to-process-long-and-short-command-line-options/12523979#12523979
    #   while [[ -n "$1" ]]; do <-- `getopts` doesn't support long args
    #       case "$1" in # <-- Read arg directly
    #           -d | --depth) ... ;;
    #       esac
    #       shift # <-- Manually shift by one arg
    #   done
    while getopts 'ic' opt; do
        # OPTIND = Arg index (equivalent to $1, $2, etc.)
        # OPTARG = Variable set to the flag (e.g. `-i myArgValue` makes OPTARG=myArgValue)
        # ${!OPTIND} = Actual flag (e.g. `-i myArgValue` makes ${!OPTIND}='-d')
        case "$opt" in
            c)
                _allowOptsAfterArgs=true
                ;;
            i)
                _parseStdin=
                ;;
            *)
                echo -e "$USAGE"
                return 1
                ;;
        esac
    done

    shift "$(( OPTIND - 1 ))"


    declare -n _parentOptionsConfig="$1" 2>/dev/null

    if [[ -z "$1" ]]; then
        echo -e "$USAGE"
        return 1
    fi

    shift


    declare -A getoptsParsingConfig=()
    declare getoptsStr=''

    if [[ -n "${_parentOptionsConfig[':']+true}" ]]; then
        # Append colon to beginning if specified, silencing
        # all unrecognized flags and flags lacking args which require them.
        getoptsStr=':'

        # Remove from map since we want to iterate over it later
        unset _parentOptionsConfig[':']
    fi

    declare hasUnknownFlagHandler=

    # Mark if an unknown-flag handler has been set, even if it's blank;
    # `${var+word}` will return `word` if the value is set or blank (e.g. `declare var=`),
    # but not if it is null (e.g. `declare var`)
    if [[ -n "${_parentOptionsConfig['?']+hasHandler}" ]]; then
        hasUnknownFlagHandler=true
    fi

    # Extract custom unknown-option and USAGE entries from parent config
    # so they aren't parsed into `getoptsParsingConfig`
    #
    # Extract unknown-flag handler function (passed to `eval`)
    # Replace any occurrence of "USAGE" with the custom-formatted one generated in this function
    declare unknownFlagHandler="${_parentOptionsConfig['?']}"
    unknownFlagHandler="${unknownFlagHandler//USAGE/parentUsageStr}"
    unset _parentOptionsConfig['?']
    # FUNCNAME is an array of the function call stack - 0=thisFunc, 1=parentFunc, 2=grandparentFunc, etc.
    declare parentUsageStr="${FUNCNAME[1]} ${_parentOptionsConfig['USAGE']}"
    unset _parentOptionsConfig['USAGE']
    # Create new option-usage map for easier parent-usage printing.
    # Allows us to avoid nested for-loops later to match parsed-config keys to
    # parent-config descriptions.
    declare -A parentUsageOptions=()

    declare optConfigKey

    for optConfigKey in "${!_parentOptionsConfig[@]}"; do
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
            parentUsageOptionKey="-$getoptsShort, --$getoptsLong"
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
        parentUsageOptions["$parentUsageOptionKey"]="${_parentOptionsConfig["$optConfigKey"]}"
    done

    # Add ability to parse long options, e.g. `--optName`
    # but only do so if options were specified (otherwise `getopts` throws an error)
    if [[ -n "$getoptsStr" ]]; then
        getoptsStr+='-:'
    fi

    # Add short/long options and their descriptions to parent's USAGE string
    # only if it's present.
    # Use keys from `getoptsParsingConfig` since it already parsed long/short
    # options, then get the description from the original parent config.
    if [[ -n "$parentUsageStr" ]] && ! array.empty parentUsageOptions; then
        parentUsageStr+="\n    Options:\n"
        declare indentationAmount="        "
        declare optionUsageStr=''
        declare optionUsageKey

        for optionUsageKey in "${!parentUsageOptions[@]}"; do
            declare optionUsageDesc="${parentUsageOptions["$optionUsageKey"]}"
            # Use tab to separate key-value string for later `column` usage for auto-spacing columns
            declare optionUsageEntry="$indentationAmount$optionUsageKey\t|\t$optionUsageDesc\n"

            optionUsageStr+="$optionUsageEntry"
        done

        # `column` converts strings into tables.
        # For our usage, this makes the space between option keys and
        # descriptions evenly spaced so that all descriptions line up.
        # `-t` = Convert to table (i.e. make it evenly spaced)
        # `-c N` = Make N columns; On WSL, it's is max-width in characters;
        #   Try both `-c numCols` and `-c maxWidth` to find which one you need to use.
        #   Could also use as max-width to make table less wide than the full terminal width.
        # `-s delim` = Use specified string as a delimiter rather than all whitespace.
        #   Specify tab since spaces are used in description strings.
        # `-W colIndex` = Column index that is allowed to wrap text content into multi-line cells;
        #   If using with `-c`,
        # `-l maxNumCols` = Maximum number of columns; if more entries than num cols, all entries will be
        #   concatenated into the last column.
        #
        # Alternative for wrapping text manually:
        #   fold -s -w $(tput cols)
        #
        # TODO maybe just `printf` would do better by making wrapping of long description
        # strings remain flush with the description-start column.
        # See: https://www.linuxjournal.com/content/bashs-built-printf-function
        declare _helpOptionsColumnWidth=3

        if isWsl; then
            _helpOptionsColumnWidth=$(tput cols)
        fi

        parentUsageStr+="$(
            echo -e "$optionUsageStr" \
                | column -t -c $_helpOptionsColumnWidth -s $'\t' -W $_helpOptionsColumnWidth \
                2>/dev/null
        )"

        if (( $? )); then
            parentUsageStr+="$(
                echo -e "$optionUsageStr" \
                    | column -t -c $_helpOptionsColumnWidth -s $'\t'
            )"
        fi
    fi


    # Ways to parse STDIN:
    #
    # To simultaneously read from stdin/output to stdout as lines come in (e.g. grep):
    #   while read stdinLine [or: var1 var2 ...]; do
    #       someCommand stdinLine
    #   done >&1
    #
    # To wait for them all to come in, and then read them all into an array:
    #   readarray -t stdin
    #
    # Skip all the difficulty of redirections by reading from one of the special `/dev/std(in|out|err)` files,
    # though this will block code execution if STD(IN|OUT|ERR) are empty.
    #   e.g.
    #       myCommandAcceptingBothArgsAndStdin "$@" < /dev/stdin
    #       cat /dev/stdin | myCommand
    #   See:
    #       http://manpages.ubuntu.com/manpages/trusty/en/man1/bash.1.html#:~:text=Bash%20handles%20several%20filenames%20specially%20when%20they%20are%20used%20in%20redirections%2C%20as%20%20described%0A%20%20%20%20%20%20%20in%20the%20following%20table%3A
    if [[ -n "$_parseStdin" ]] && [[ -p /dev/stdin ]]; then
        # We must check if /dev/stdin is open with `test -p` first.
        # Otherwise, `readarray` will block indefinitely.
        #
        # See:
        #   https://unix.stackexchange.com/questions/33049/how-to-check-if-a-pipe-is-empty-and-run-a-command-on-the-data-if-it-isnt
        declare -n _stdin='stdin'
        _stdin=()

        # Note: we can't use `read -r -d '' -t 0 [-a] _stdin` b/c for some reason
        # it doesn't capture STDIN for the parent function correctly.
        #
        # See:
        #   https://www.baeldung.com/linux/reading-output-into-array
        #   https://www.reddit.com/r/commandline/comments/iev25m/how_can_i_timeout_a_readarray_in_bash/
        readarray -t _stdin
    fi


    declare -n remainingArgs="argsArray"
    remainingArgs=()


    opt=
    OPTIND=1
    declare prevOptind=$OPTIND # Helps split single-hyphen, multi-char unknown flags. See below for details.

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
            # TODO maybe this would be simpler:
            #   read key val < <(echo "${x/=/ }")
            #       String substitution - remove first '=' but not subsequent ones
            #       Read the resulting 'myKey myValWithAnyCharsIncluding=This' into `key` and `val` respectively
            #       See: https://stackoverflow.com/a/12739533/5771107
            # Also worth noting: you can set vars by name with `printf`
            #   printf -v "$varHoldingNewVarName" '%s' "$varHoldingNewVarValue"
            #       See: https://stackoverflow.com/a/13717788/5771107
            # Or, set vars to positional args
            #   set -- val1 val2 "$@"  # Puts `val1` and `val2` before the rest of the args
            #       See: https://unix.stackexchange.com/a/308263/203387
            declare _longOptionArray
            declare _longOptionValArray
            array.fromString -d '=' -r _longOptionArray "$OPTARG"
            array.slice -r _longOptionValArray _longOptionArray 1

            declare _longOptionKey="${_longOptionArray[0]}"
            declare _longOptionVal="$(array.join _longOptionValArray '=')"

            if [[ -z "$_longOptionVal" ]]; then
                # Handle long options with spaces:
                # `--long-opt MyValue` instead of `--long-opt=MyValue`
                # If `$_longOptionVal` is empty, then the long option as a ' ' rather than a '=' in it.
                # Thus, check if option config wants an argument for this; if so, manually add it.
                declare _parentOptionsConfigKeys="${!_parentOptionsConfig[@]}"

                if array.contains _parentOptionsConfigKeys "$_longOptionKey:"; then
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
        declare optKey

        for optKey in "${!getoptsParsingConfig[@]}"; do
            # `optKey` is what's defined in the config matrix, e.g. `s|some-arg`
            # `opt` is what the user actually passed in, e.g. either `s` or `some-arg`
            # For the regex match to work using `=~`, we must use:
            #   "string" =~ pattern
            # and `pattern` must not be quoted, otherwise it will be parsed as literal chars, not regex
            if [[ "$opt" =~ ^$optKey$ ]]; then
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

                # Track OPTIND for each known flag to handle single-hyphen, multi-char unknown flags
                prevOptind=$OPTIND
            fi
        done

        if [[ -z "$optHandled" ]]; then
            # `opt` and `OPTARG` were manually parsed above, but that only works for known flags.
            # Since we now need to parse an unknown flag, we don't know what format it took
            # so we can't use the helpful manual parsing from above.
            # e.g. We can't blindly use `OPTARG` b/c if the unknown flag has no args,
            # then `OPTARG` would be the next flag after the unknown one.
            declare unknownFlagIndex=$(( OPTIND - 1 ))
            declare unknownFlag="${!unknownFlagIndex}"
            # The next arg after the unknown flag - Either the flag arg, a different flag,
            # or a positional (non-flag) arg to the parent function.
            declare unknownFlagMaybeValueIndex=$OPTIND
            declare unknownFlagMaybeValue="${!unknownFlagMaybeValueIndex}"
            # The next next arg after the unknown flag - Either a flag after the unknown flag's
            # arg (which we care about for using `shift`), or anything else (which we don't
            # care about since it doesn't affect `shift`).
            declare nextFlagMaybeIndex=$(( OPTIND + 1 ))
            declare nextFlagMaybe="${!nextFlagMaybeIndex}"

            if [[ -n "$_allowOptsAfterArgs" ]]; then
                # If trying to parse args after an unknown one, then chances are, the parent function
                # is trying to wrap another function and allow forwarding its flags to said function.
                #
                # `getopts` goes letter by letter, meaning that it will fail for functions that wrap
                # other functions which break standard option format, e.g. using a single hyphen for
                # long option names.
                # For example, `find` uses `-maxdepth` instead of `--maxdepth`, which would result
                # in `getopts` going letter-by-letter when iterating, e.g.
                # `findWrapper --allowed-flag -maxdepth 3` would result in `m`, `a`, `x`, `d`, etc.
                # each being iterated through individually.
                #
                # As such, we want to account for this by taking the whole arg as one and then continue
                # on as if it were formatted properly.
                # BUT only do so if the parent specifies this b/c otherwise function wrappers for
                # single-letter flags with values, e.g. `grep -A5` will fail.
                remainingArgs+=("$unknownFlagMaybeValue")

                prevOptind=$OPTIND
                (( OPTIND++ ))

                continue
            elif [[ -n "$hasUnknownFlagHandler" ]]; then
                eval "$unknownFlagHandler"

                if (( $OPTIND == $prevOptind )); then
                    # NOTE: OPTIND only increments if the flag is in "standard" format,
                    # e.g. `-a Val` or `-a=Val`
                    # But in the case of a flag merged with other flags and/or their values,
                    # e.g. `-aVal` or `-abc Val` or `-abcVal` or `-abc == -a -b -c`
                    # then it's NOT incremented until it reaches the end of the string.
                    #
                    # This is because OPTIND technically holds the index of the *next*
                    # arg, and `getopts` hasn't encountered the next arg yet b/c it's stuck
                    # iterating on the merged flag(s) characters one-by-one.
                    # See: https://unix.stackexchange.com/questions/214141/explain-the-shell-command-shift-optind-1/214151
                    #
                    # Some common analogies IRL:
                    #   find -iname val
                    #   grep -B4
                    # Though, technically, these would still be handled by `getopts` as expected since they're defined in
                    # the getopts string, i.e. find -> opt=i, OPTIND=2, OPTARG=val
                    #
                    # Thus, in this situation, just skip it since a future iteration will capture
                    # the whole string.
                    #
                    # An alternative would be to try to split the characters manually,
                    # e.g. `echo '-abcd' | sed -E 's/\W*(\w)\W*/-\1 /g'`
                    # but this might mess up whatever these flags are passed to by the parent,
                    # so just leave them as-is and let the parent handle them itself.
                    continue
                fi

                if [[ "$unknownFlag" == '-h' || "$unknownFlag" == '--help' ]]; then
                    # Make next iteration execute the "help" sequence by removing the handler
                    # and back-tracking by one arg
                    hasUnknownFlagHandler=
                    (( OPTIND-- ))
                elif [[ "$unknownFlag" =~ = ]]; then
                    # Unknown flag had an equals sign, e.g. `-a=b` or `--aa=b`
                    # so we don't have to worry about the next arg after it,
                    # and we can just add the whole thing directly to `argsArray`
                    remainingArgs+=("$unknownFlag")
                elif [[ "$unknownFlag" =~ ^- ]]; then
                    # Unknown flag had a space, e.g. `-a b` or `--aa b` or `-a -x` or `--aa --xx`
                    # so we don't know if a known flag comes after it or two entries after it

                    if [[ "$unknownFlagMaybeValue" =~ ^- ]]; then
                        # Next arg is a flag, e.g. `-a -x`
                        # so add the flag alone without the value and continue.
                        # The next `getopts` iteration will handle the next flag
                        remainingArgs+=("$unknownFlag")
                    elif [[ "$nextFlagMaybe" =~ ^- ]]; then
                        # Next arg is not a flag, but the one after it is, e.g. `-a A -x`
                        # so add both the unknown flag and its argument value to `argsArray`.
                        # The next `getopts` iteration will handle the next flag
                        remainingArgs+=("$unknownFlag" "$unknownFlagMaybeValue")
                        # Skip past the unknown flag's value so the next `getopts` iteration sees
                        # the next flag instead of the unknown flag's value
                        shift
                    else
                        # Neither the next arg nor the one after it are flags, e.g. `-a x y`
                        # so simply add the unknown flag to `argsArray`.
                        # We don't need to `break` out of the loop since `getopts` will see that
                        # neither the next arg nor the one after it are flags, so it will stop iterating
                        # through args itself.
                        remainingArgs+=("$unknownFlag")
                    fi
                fi
            else
                echo -e "$parentUsageStr" >&2

                return 1
            fi
        fi
    done

    shift "$(( OPTIND - 1 ))"

    remainingArgs+=("$@")
}



_testParseArgs() (
    echo "Note: Args passed to ${FUNCNAME[0]} will be used as a custom unknown-flag handler command.
    No args will use the default parsing-halting/USAGE-printing behavior of \`parseArgs\`.
    "

    declare handler=

    if [[ -n "$@" ]]; then
        handler="$@"
    fi

    testMe() (
        declare aFlag
        declare bFlag
        declare cFlag
        declare argsArray
        declare -A options=(
            ['a|asdf:,aFlag']='A usage str'
            ['b|bvcx:,bFlag']='B usage str'
            ['c|cdef,cFlag']='C usage str'
            [':']=
        )

        if [[ -n "$handler" ]]; then
            options['?']="$handler"
        fi

        parseArgs options "$@"
        declare retVal="$?"

        echo "aFlag(${#aFlag[@]})=${aFlag[@]}"
        echo "bFlag(${#bFlag[@]})=${bFlag[@]}"
        echo "cFlag(${#cFlag[@]})=${cFlag[@]}"
        echo "$(array.toString argsArray)"
        echo "\$@=$@"
    )

    testMe --asdf=ASDF -a 'FD SA' --bvcx BBB -H -c 'hello world' yo
)
