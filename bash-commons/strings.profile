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

    parseArgs _strJoinOptions "$@"
    (( $? )) && return 1


    declare _strJoinInput="${argsArray[@]}"

    if [[ -z "$_strJoinInput" ]]; then
        _strJoinInput="$(egrep '.' < /dev/stdin)"
    fi

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
        echo "${_strJoinOutput/%$_strJoinStr}"
    else
        echo "$_strJoinOutput"
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

    parseArgs _strUniqueOptions "$@"
    (( $? )) && return 1

    declare _strUniqueInput="${argsArray[@]}"

    if [[ -z "$_strUniqueInput" ]]; then
        _strUniqueInput="$(egrep '.' < /dev/stdin)"
    fi

    _strUniqueDelim="${_strUniqueDelim:-\n}"


    declare _strUniqueOutput="$_strUniqueInput"

    # If using a white-space character
    if [[ -n "$_strUniqueDelim" && "$_strUniqueDelim" != '\n' ]]; then
        _strUniqueOutput="$(str.join -d "$_strUniqueDelim" -j '\n' "$_strUniqueInput")"
    fi

    # `awk` uses `u` to check if the line is unique, regardless of location; if it is not,
    # then advance the line number by 1 so we skip over the duplicate line.
    # This is the opposite of `uniq` which only checks unique entries that are neighbors, and
    # maintains order unlike `sort -u`.
    #
    # See:
    #   https://stackoverflow.com/questions/13648410/how-can-i-get-unique-values-from-an-array-in-bash
    #   https://stackoverflow.com/questions/30232973/list-the-uniq-lines-based-on-delimiter
    _strUniqueOutput="$(echo "$_strUniqueOutput" | awk '!u[$NF]++')"

    str.join -d '\n' -j "$_strUniqueDelim" "$_strUniqueOutput"
}
