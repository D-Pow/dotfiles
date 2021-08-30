# Before if-statement before case-statement
# ./test.sh -ab -c=V -x=HI --f=y --gd --alpha=bravo=charlie hello
# a - NAME=a - OPTIND(1)=-ab - OPTARG=
# b - NAME=b - OPTIND(2)=-c=V - OPTARG=
# c - NAME=c - OPTIND(3)=-x=HI - OPTARG==V
# \* - NAME=? - OPTIND(3)=-x=HI - OPTARG=x
# \* - NAME=? - OPTIND(3)=-x=HI - OPTARG==
# \* - NAME=? - OPTIND(3)=-x=HI - OPTARG=H
# \* - NAME=? - OPTIND(4)=--f=y - OPTARG=I
# '-' - NAME=- - OPTIND(5)=--gd - OPTARG=f=y
# '-' - NAME=- - OPTIND(6)=--alpha=bravo=charlie - OPTARG=gd
# '-' - NAME=- - OPTIND(7)=hello - OPTARG=alpha=bravo=charlie
# Rest: hello


# Example:
#
# declare -A config=(
#     ['a|alpha:']='First arg'
#     ['b']='Second arg'
#     ['c:']='Third arg'
#     ['f:']='F arg'
#     ['x:']='My x'
#     ['|gd']='Only long'
# )
# parseArgs config "$@"

parseArgs() {
    declare -n argConfig="$1"

    shift

    declare getoptsStr=''

    if [[ -n "${argConfig[':']+true}" ]]; then
        # Append colon to beginning if specified, silencing
        # all unrecognized flags and flags lacking args which require them.
        getoptsStr=':'

        # Remove from map since we want to iterate over it later
        unset argConfig[':']
    fi

    getoptsStr+=':-:'

    for argKey in "${!argConfig[@]}"; do
        getoptsStr+="$(echo "$argKey" | sed -E 's/\|[^:]+//g')"
    done

    # echo "$getoptsStr"
    # return

    declare OPTIND=1

    while getopts "$getoptsStr" opt; do
        if [[ "$opt" == "-" ]]; then
            # Handle long options:
            # `--alpha bravo | --alpha=bravo` --> OPT='alpha', OPTARG='bravo'
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

        # TODO how to split keys into case entries
        case "$opt" in
            a|alpha)
                echo "a - NAME=$opt - OPTIND($OPTIND)=${!OPTIND} - OPTARG=$OPTARG"
                ;;
            b)
                echo "b - NAME=$opt - OPTIND($OPTIND)=${!OPTIND} - OPTARG=$OPTARG"
                ;;
            c)
                echo "c - NAME=$opt - OPTIND($OPTIND)=${!OPTIND} - OPTARG=$OPTARG"
                ;;
            d)
                echo "d - NAME=$opt - OPTIND($OPTIND)=${!OPTIND} - OPTARG=$OPTARG"
                ;;
            e)
                echo "e - NAME=$opt - OPTIND($OPTIND)=${!OPTIND} - OPTARG=$OPTARG"
                ;;
            :)
                # Special key for capturing flags that should have arguments but don't
                echo "':' - NAME=$opt - OPTIND($OPTIND)=${!OPTIND} - OPTARG=$OPTARG"
                echo "Missing argument for $OPTARG" >&2
                ;;
            -)
                # Manual capturing of long flags, e.g. `--flag`
                # Must be used with `getopts '-:'` so the `-flag` after the first `-`
                # is treated as the argument to `-`.
                # Also need to manually handle `--flag arg` vs `--flag=arg`
                echo "'-' - NAME=$opt - OPTIND($OPTIND)=${!OPTIND} - OPTARG=$OPTARG"
                ;;
            *)
                # Both `\?` and `*` mean the same thing: invalid option.
                # Regardless of which is used, `$opt` will be set to `'?'`.
                #
                # If getopts string is preceded by a colon - `getopts ':...'`
                # then built-in errors will be silenced, including
                # "Invalid option" and "Missing argument for option"
                echo "\* - NAME=$opt - OPTIND($OPTIND)=${!OPTIND} - OPTARG=$OPTARG"
                ;;
        esac
    done

    shift "$((OPTIND - 1))"

    echo "Rest: $@"
}

