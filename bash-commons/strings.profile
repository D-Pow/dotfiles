trim() {
    # TODO Allow trimming spaces from beginning/end of lines instead of only trimming lines
    #   See: https://stackoverflow.com/questions/20600982/trim-leading-and-trailing-spaces-from-a-string-in-awk
    declare USAGE="[OPTIONS...] <input-string-or-stdin>
    Removes the number of lines (rows) from the top/bottom of the input.
    Also trims leading/trailing white-space from each line by default.
    "
    declare _trimTop=
    declare _trimBottom=
    declare _noTrimWhitespace=
    declare argsArray=
    declare stdin=
    declare -A _trimOptions=(
        ['t|top:,_trimTop']='Number of lines to remove from the top of the input.'
        ['b|bottom:,_trimBottom']='Number of lines to remove from the bottom of the input.'
        ['s|no-whitespace,_noTrimWhitespace']='Keeps leading/trailing white-space on each line.'
        [':']=
        ['USAGE']="$USAGE"
    )

    parseArgs _trimOptions "$@"
    (( $? )) && return 1


    declare _trimInputArray=("${stdin[@]}" "${argsArray[@]}")
    declare _trimOutputArray=()

    declare _trimInputline
    for _trimInputline in "${_trimInputArray[@]}"; do
        if [[ -z "$_noTrimWhitespace" ]]; then
            _trimOutputArray+=("$(echo "$_trimInputline" | sed -E 's/(^\s+)|(\s+$)//g')")
        else
            _trimOutputArray+=("$_trimInputline")
        fi
    done

    # Re-join input lines by \n to maintain original input format
    declare _trimOutput="$(array.join _trimOutputArray '\n')"

    if [[ -n "$_trimTop" ]]; then
        # `tail -n` accepts `numLinesToShowFromBottom` or `+(numLinesToRemoveFromTop + 1)`
        _trimOutput="$(echo "$_trimOutput" | tail -n "+$(( _trimTop + 1 ))")"
    fi

    if [[ -n "$_trimBottom" ]]; then
        # `head -n` accepts `numLinesToShowFromTop` or `-numLinesToRemoveFromBottom`
        _trimOutput="$(echo "$_trimOutput" | head -n "-$_trimBottom")"
    fi

    echo "$_trimOutput"
}


decolor() {
    # Strips coloring/bolding from text
    #
    # See:
    #   https://stackoverflow.com/questions/17998978/removing-colors-from-output
    sed -E 's/\x1B\[(;?[0-9]{1,3})+[mGK]//g' | sed -E 's/\x1B\[([0-9]{1,3}(;[0-9]{1,2})?)?[mGK]//g'
}


str.repeat() {
    declare _strToRepeat="$1"
    declare _strRepeatTimes="$2"

    if (( _strRepeatTimes <= 0 )); then
        echo

        return
    fi

    # Similar to Java's formatting (e.g. `%.2f` prints to 2 decimal places),
    # this "hack" prints the supplied string to 0 decimal places, i.e. doesn't print the string
    # at all.
    #
    # Using this hack, we can print the desired string `n` times because the results from `seq` are
    # erased from the output.
    #
    # Ref: https://superuser.com/questions/86340/linux-command-to-repeat-a-string-n-times/86342#86342
    printf "$_strToRepeat%.0s" $(seq 1 "$_strRepeatTimes")
}


str.upper() {
    # `&` is a special character that means "all of the input that matched the pattern"
    # It's the equivalent of capturing the entire string and then handling it via match group, e.g.
    #   sed -E 's/(^.*$)/\U\1/g'
    #
    # See:
    #   https://unix.stackexchange.com/questions/296705/using-sed-with-ampersand/296732#296732
    echo "$@" | sed -E 's/./\U&/g'
}


str.lower() {
    echo "$@" | sed -E 's/./\L&/g'
}


str.join() {
    declare USAGE="[-d|--delimiter <delimiter>=\\\\n] [-j|--join-str <joinStr>] <args-or-stdin>
    Joins the string (supplied from args or STDIN) that is split with the specified \`delimiter\` using
    the specified \`joinStr\`.

    Both \`delimiter\` and \`joinStr\` should be quoted, e.g. \`-j '\\\\n' <string>\`
    "
    declare _strJoinDelim=
    declare _strJoinStr=
    declare -A _strJoinOptions=(
        ['d|delimiter:,_strJoinDelim']='Delimiter used to separate strings being read'
        ['j|join-str:,_strJoinStr']='Delimiter to use when joining strings'
        [':']=
        ['USAGE']="$USAGE"
    )
    declare argsArray
    declare stdin

    parseArgs _strJoinOptions "$@"
    (( $? )) && return 1


    declare _strJoinInputArray=("${stdin[@]}" "${argsArray[@]}")
    declare _strJoinInput="${_strJoinInputArray[@]}"

    _strJoinDelim="${_strJoinDelim:-\n}"


    # Don't use `printf` or change `IFS` so the delimiters are replaced instead of left in, and
    # so normal string parsing (i.e. `"$(cmd)"` instead of `$(cmd)`) is allowed since that's the
    # best way to print white-space characters.
    declare _strJoinOutput="$(echo "$_strJoinInput" | tr -s "$_strJoinDelim" "$_strJoinStr")"


    # If the join-string isn't a white-space char (space, \n, \t, etc.), then remove it since
    # it will be appended at the end of the string from the `tr` call.
    # Otherwise, don't try to remove white-space chars because the pattern substitution to remove
    # the last character won't interpret backslashes.
    # This is checked by coercing the join-string to an interpreted character, which affects
    # escaped/backslashed chars but leaves non-escaped chars as-is.
    #
    # Note: Different combinations of `tr -d`, `printf`, `${output/%?($delim|\$\'delim\')}`, etc.
    # were attempted, but they all failed if the delimiter were white-space.
    # Thus, we have to do a manual check via if-statement.
    #
    # See:
    #   https://tldp.org/LDP/abs/html/parameter-substitution.html
    #   https://stackoverflow.com/questions/28256178/how-can-i-match-spaces-with-a-regexp-in-bash/28256343#28256343
    if ! [[ "$(echo -e \$\'$_strJoinStr\')" =~ [[:space:]] ]]; then
        echo -e "${_strJoinOutput/%$_strJoinStr}"
    else
        echo -e "$_strJoinOutput"
    fi
}


str.unique() {
    declare USAGE="[-d|--delimiter <delimiter>=\\\\n] <args-or-stdin>
    Returns only the unique portions of a string (supplied from args or STDIN) that is split with the
    specified \`delimiter\`.

    \`delimiter\` should be quoted, e.g. \`-d '\\\\n' <string>\`
    "
    declare _strUniqueDelim=
    declare -A _strUniqueOptions=(
        ['d|delimiter:,_strUniqueDelim']='Delimiter used to separate strings being read'
        [':']=
        ['USAGE']="$USAGE"
    )
    declare argsArray
    declare stdin

    parseArgs _strUniqueOptions "$@"
    (( $? )) && return 1


    declare _strUniqueInputArray=("${stdin[@]}" "${argsArray[@]}")
    declare _strUniqueInput="${_strUniqueInputArray[@]}"

    _strUniqueDelim="${_strUniqueDelim:-\n}"


    declare _strUniqueOutput="$_strUniqueInput"

    # If using a white-space character
    if [[ -n "$_strUniqueDelim" && "$_strUniqueDelim" != '\n' ]]; then
        _strUniqueOutput="$(str.join -d "$_strUniqueDelim" -j '\n' "$_strUniqueInput")"
    fi

    # `awk` unique checks work regardless of location.
    # This is the opposite of `uniq` which only checks unique entries that are neighbors, and
    # maintains order unlike `sort -u`.
    #
    # Command breakdown:
    #   `u` == Unique
    #   `NF` == Row index
    #   Default command if none specified == `print $0`
    # Result: If the row's value is not unique for the entire set of rows, then skip over the
    # line (via `++`) rather than printing it.
    #
    # See:
    #   https://stackoverflow.com/questions/13648410/how-can-i-get-unique-values-from-an-array-in-bash
    #   https://stackoverflow.com/questions/30232973/list-the-uniq-lines-based-on-delimiter
    _strUniqueOutput="$(echo "$_strUniqueOutput" | awk '!u[$NF]++')"

    str.join -d '\n' -j "$_strUniqueDelim" "$_strUniqueOutput"
}


str.replace() {
    # String replacement: https://tldp.org/LDP/abs/html/parameter-substitution.html
    declare USAGE="[OPTION]... <PatternToReplace> <Replacement> [StringToAlter]...
    Replaces \`PatternToReplace\` occurrence(s) with \`Replacement\` within all \`StringToAlter\` arguments.
    Optionally, executes each \`StringToAlter\` replacement in the way specified by the (mutually exclusive) options.
    Note: Patterns are globs, not regex.
    "
    declare _strReplaceGlobally=
    declare _strReplaceFirstMatch=
    declare _strReplacePrefix=
    declare _strReplaceSuffix=
    declare argsArray
    declare stdin
    declare -A _strReplaceOptions=(
        ['g|global,_strReplaceGlobally']='Replace the pattern globally.'
        ['f|first,_strReplaceFirstMatch']='Replace only the first match (default).'
        ['p|prefix,_strReplacePrefix']='Replace only matches at the beginning of the string.'
        ['s|suffix,_strReplaceSuffix']='Replace only matches at the end of the string.'
        ['USAGE']="$USAGE"
    )

    parseArgs _strReplaceOptions "$@"
    (( $? )) && return 1


    declare _strReplacePattern="${argsArray[0]}"
    declare _strReplaceReplacement="${argsArray[1]}"

    declare _strReplaceStrings=()
    array.slice -r _strReplaceStrings argsArray 2
    _strReplaceStrings=("${stdin[@]}" "${_strReplaceStrings[@]}") # Inject STDIN before args

    declare _strReplaceString

    for _strReplaceString in "${_strReplaceStrings[@]}"; do
        declare _strReplaceOutput="$_strReplaceString"

        if [[ -n "$_strReplaceGlobally" ]]; then
            # See: https://tldp.org/LDP/abs/html/parameter-substitution.html#:~:text=%24%7Bvar//Pattern/Replacement%7D
            _strReplaceOutput="${_strReplaceString//$_strReplacePattern/$_strReplaceReplacement}"
        elif [[ -n "$_strReplaceFirstMatch" ]]; then
            # See: https://tldp.org/LDP/abs/html/parameter-substitution.html#:~:text=%24%7Bvar/Pattern/Replacement%7D
            _strReplaceOutput="${_strReplaceString/$_strReplacePattern/$_strReplaceReplacement}"
        elif [[ -n "$_strReplacePrefix" ]]; then
            # See: https://tldp.org/LDP/abs/html/parameter-substitution.html#:~:text=%24%7Bvar/%23Pattern/Replacement%7D
            #
            # Similar to longest prefix removal: https://tldp.org/LDP/abs/html/parameter-substitution.html#:~:text=%24%7Bvar%23Pattern%7D%2C%20%24%7Bvar%23%23Pattern%7D
            #   Shortest: ${var#Pattern}
            #   Longest: ${var##Pattern}
            _strReplaceOutput="${_strReplaceString/#$_strReplacePattern/$_strReplaceReplacement}"
        elif [[ -n "$_strReplaceSuffix" ]]; then
            # See: https://tldp.org/LDP/abs/html/parameter-substitution.html#:~:text=%24%7Bvar/%25Pattern/Replacement%7D
            #
            # Similar to longest suffix removal: https://tldp.org/LDP/abs/html/parameter-substitution.html#:~:text=%24%7Bvar%23Pattern%7D%2C%20%24%7Bvar%23%23Pattern%7D
            #   Shortest: ${var%Pattern}
            #   Longest: ${var%%Pattern}
            _strReplaceOutput="${_strReplaceString/%$_strReplacePattern/$_strReplaceReplacement}"
        fi

        echo "$_strReplaceOutput"
    done
}


convertMillisToReadable() {
    declare USAGE="[options...] < STDIN
    Converts text containing milliseconds that may or may not be Unix Epoch timestamps into readable date/time strings.
    "
    declare _convertMillisRemoveDate
    declare _convertMillisRemoveTimezone
    declare _convertMillisPrefix
    declare _convertMillisSuffix
    declare _convertMillisJson
    declare _convertMillisStr
    declare argsArray
    declare -A _convertMillisOptions=(
        ['j|json,_convertMillisJson']='Use `jq` to parse entries (must map entries before piping here).'
        ['s|string,_convertMillisStr']='Use `awk` to parse text files containing `timestampNumber (ms|millis|sec|min|etc.)`.'
        ['p|prefix:,_convertMillisPrefix']='String to prepend to the specified command (e.g. `map(` for `jq`).'
        ['e|suffix:,_convertMillisSuffix']='String to append to the specified command (e.g. `)` for `map(` prefix for `jq`).'
        ['d|remove-date,_convertMillisRemoveDate']='Remove date string from output.'
        ['z|remove-timezone,_convertMillisRemoveTimezone']='Remove timezone string from output.'
        ['USAGE']="$USAGE"
    )

    parseArgs _convertMillisOptions "$@"
    (( $? )) && return 1

    declare _convertMillisDateFormat='%m/%d/%Y-'
    declare _convertMillisTimeFormat='%H:%M:%S'
    declare _convertMillisTimezoneFormat='_(%Z)'

    if [[ -n "$_convertMillisRemoveDate" ]]; then
        _convertMillisDateFormat=
    fi

    if [[ -n "$_convertMillisRemoveTimezone" ]]; then
        _convertMillisTimezoneFormat=
    fi


    if [[ -n "$_convertMillisJson" ]]; then
        if [[ -n "$_convertMillisPrefix" ]] && ! echo "$_convertMillisPrefix" | egrep -q '\| ?$'; then
            _convertMillisPrefix="$_convertMillisPrefix | "
        fi

        # See:
        #   Repo: https://github.com/stedolan/jq
        #   Docs: https://stedolan.github.io/jq/manual
        #   Builtins: https://stedolan.github.io/jq/manual/#Builtinoperatorsandfunctions
        #   Handling timestamps: https://stackoverflow.com/questions/36853202/jq-dates-and-unix-timestamps
        #   Transforming current/creating-temp objects: https://stackoverflow.com/questions/31764035/transforming-nested-array-of-objects-using-jq
        #   Adding new fields: https://stackoverflow.com/questions/52441157/jq-add-properties-to-nested-object-in-nested-array
        #   Combining multiple fields into one: https://stackoverflow.com/questions/28164849/using-jq-to-parse-and-display-multiple-fields-in-a-json-serially
        #   Conditionals: https://unix.stackexchange.com/questions/672784/jq-set-a-value-to-another-value-conditionally

        jq "$_convertMillisPrefix
        if tostring | length == 13 then
            # 13 digits contain milliseconds, which is unrecognizable by the \`strftime\` C function.
            # So strip them from the input and convert them into a string.
            {
                base: (. / 1000 | floor),
                millis: (. / 1000 | tostring | match(\"(\\\\d{3})\$\") | \".\" + .string)
            }
        elif tostring | length == 10 then
            {
                base: .,
                millis: \"\"
            }
        # else
            # TODO Manual string parsing like \`awk\`
        end
        # Final string creation: Net result: 01/27/2000-13:45:55.123_(EST)
        # Format Unix Epoch timestamp without timezone.
        | (
            .base
            | strftime(\"$_convertMillisDateFormat$_convertMillisTimeFormat\")
        )
        # Append milliseconds if they exist after seconds.
        + .millis
        # Append the timezone after any possible milliseconds.
        + (
            ${_convertMillisTimezoneFormat:+".base | strftime(\"$_convertMillisTimezoneFormat\") + "}
            \"\"
        )
        # TODO This doesn't work! See: https://stackoverflow.com/questions/31658278/terminating-jq-processing-when-condition-is-met
        # Fallback to original number
        // .
        $_convertMillisSuffix"

        return
    fi

    echo "TODO Touch up the rest"
    return 1


    # See:
    #   Unix timestamps to readable: https://unix.stackexchange.com/questions/265950/convert-unix-timestamp-to-hhmmsssss-where-sss-is-milliseconds-in-awk
    #   `awk` time functions: https://www.gnu.org/software/gawk/manual/html_node/Time-Functions.html
    #   `awk` string functions: https://www.gnu.org/software/gawk/manual/html_node/String-Functions.html

    awk --re-interval '{
        $0=gensub(/([0-9]+),+/, "\\1", "g")
        minutes=gensub(/.*[^0-9]([0-9]{6,}[0-9.]*)[^0-9].*/, "\\1", "g")
        minutesConverted=minutes / 60

        # printf("\n\nMins: %s => %s\n", minutes, minutesConverted)

        if (minutesConverted > 0) {
            # Regex must be extracted to separate string b/c of var injection
            # See:
            #   https://stackoverflow.com/questions/3686204/how-can-i-mix-math-with-regexs-in-awk-or-sed
            #   https://stackoverflow.com/questions/41658836/using-shell-variables-in-gensub-in-awk
            timeRegex=sprintf("(%s) (ms|millis?|sec)", minutes)
            # `gsub(regex, replacement, [ target = $0 ]`  ==  `target=gensub(regex, replacement, "g", [ target = $0])`
            gsub(timeRegex, minutesConverted " min")
        }

        seconds=gensub(/.*[^0-9]([0-9]{4,}[0-9.]*)[^0-9].*/, "\\1", "g")
        secondsConverted=seconds / 1000

        # printf("\nSeconds: %s => %s\n", seconds, secondsConverted)

        if (secondsConverted > 0) {
            # timeRegex=sprintf("(%s) (ms|millis?)", seconds)
            # gsub(timeRegex, secondsConverted " sec")
            # `gsub` always takes variables literally, so `gsub(seconds, secondsConverted`

            # Split these calls up to avoid overwriting "min" from above
            gsub(seconds, secondsConverted)
            gsub(/(ms|millis?)/, "sec")
        }

        # Need to use `gensub` to access capture group
        $0=gensub(/([0-9]+\.[0-9]+)(\.[0-9]+)*/, "\\1", "g")

        print
    }'

    # Alternatively, convert this into a custom function and use this instead for HH:MM:SS display.
    #
    # See:
    #   `awk` time functions: https://www.gnu.org/software/gawk/manual/html_node/Time-Functions.html
    #   Custom functions: https://www.tutorialspoint.com/awk/awk_user_defined_functions.htm
    #   Manual time conversion: https://stackoverflow.com/questions/12362562/convert-milliseconds-timestamp-to-date-from-unix-command-line
    echo '' | awk '{
        millis=5253523
        sec=millis / 1000

        print millis
        print sec

        print(systime())
        print systime() + sec

        # This is what we want
        print strftime("%H:%M:%S", systime())           # Orig time
        print strftime("%H:%M:%S", systime() + sec)     # Time after `sec`

        print strftime("%H:%M:%S", systime(), 1)
        print strftime("%H:%M:%S", systime() + sec, 1)
    }'
}



_todoFancyUseOfAwk() (
    # Inspiration:
    #   https://stackoverflow.com/questions/41591828/use-bash-variable-as-array-in-awk-and-filter-input-file-by-comparing-with-array/41591888#41591888
    #   https://stackoverflow.com/questions/40846595/how-to-slice-a-variable-into-array-indexes/40848893#40848893
    # Refs:
    #   split(): https://www.gnu.org/software/gawk/manual/html_node/String-Functions.html#:~:text=split(string%2C%20array%20%5B%2C%20fieldsep%20%5B%2C%20seps%20%5D%20%5D)
    #   BEGIN/END: https://www.gnu.org/software/gawk/manual/gawk.html#Using-BEGIN_002fEND
    #   Can't use arrays as awk var: https://stackoverflow.com/questions/33105808/can-i-pass-an-array-to-awk-using-v
    declare input='
abc   4   5
abc   8   8
def   43  4
def   7   51
jkl   4   0
mno   32  2
mno   9   2
pqr   12  1
'

    declare firstColFilterArray=('abc' 'jkl' 'pqr')

    # `awk` can't accept arrays as variables, so join them by some delimiter (comma in this example)
    echo "$input" | awk -v firstColFilterString="$(array.join firstColFilterArray ',')" '
    # BEGIN runs before the rest of the program, END after
    BEGIN {
        # Split the external string variable into an awk array
        split(firstColFilterString, awkArrayFilter, ",");
    }

    {
        # Convert first-column filter from an array to a map for quick reading
        for (i in awkArrayFilter) {
            columnFilterMap[awkArrayFilter[i]];
        }

        # Check if the first column exists in the map and print it if so
        if ($1 in columnFilterMap) {
            print $0;
        }
    }
    '


    ## Other ways to do things in `awk`

    # Print all columns after a certain column example: Splitting by delimiter.
    #
    # Splitting by a delimiter (in this case, '=') to get a key/val pair,
    # and re-joining occurrences of that delimiter in val.
    # Sample use case is JS cookies where the values contain '=' such that
    # we want the first '=' occurrence to split key from val, but all subsequent
    # occurrences to be maintained within val.
    #
    # echo -e 'a=b\nc=d=e' | \
    # awk -F '=' '{
    #     key = $1;
    #     val = "";
    #
    #     for (i = 2; i <= NF; i++) {
    #         # Only prefix `val` with "=" if val was already set from a previous iteration
    #         val = length(val) > 0
    #             ? sprintf("%s=%s", val, $i)
    #             : $i;
    #     };
    #
    #     print(key, val);
    # }'
    # Note: Would be easier with two runs of `cut` (`N-` means all fields at and after N):
    # declare key="$(echo "$myVar" | cut -d '=' -f 1)"
    # declare val="$(echo "$myVar" | cut -d '=' -f 2-)"
)
