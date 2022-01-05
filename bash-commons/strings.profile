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
