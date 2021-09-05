# TODO: Review diff between $* and $@ (applies to arrays): https://stackoverflow.com/questions/12314451/accessing-bash-command-line-args-vs
# TODO:
#   Add error handling, e.g.
#       echo "${$1:?'Error message to print'}"
#   And/or default values, e.g.
#       # test first b/c Idk if you can assign arrays or if it has to be strings
#       # Alternatively, maybe use some sort of default return instead, ${2:-whatGoesHere}
#       declare -n retArr="${2:=()}"
#   array.values-from-name: Bash < 4.3 (which doesn't support `declare -n nameRef`) can be supported via:
#       eval $retArrName='("${newArr[@]}")'

array.length() {
    local -n _arrLengthArr="$1"
    local _arrLength=${#_arrLengthArr[@]}

    if (( _arrLength == 1 )) && [[ "${_arrLengthArr[@]}" == '' ]]; then
        echo 0
    else
        echo $_arrLength
    fi
}


array.empty() {
    local _lengthEmpty=`array.length $1`

    # Want to be able to use this like `if array.empty myArr; then ...`
    # Options on how to do this:
    #
    # Manually echo true/false. echo is required to return value from a function if in one-liner,
    # but isn't required if "calling" the command directly.
    # `[[ $_lengthEmpty -eq 0 ]] && echo true || echo false`
    #
    # Replace `echo` with "calling" the command directly.
    # if [[ $_lengthEmpty -eq 0 ]]; then
    #     true
    # else
    #     false
    # fi
    #
    # Or, simply run the check in-place.
    [[ $_lengthEmpty -eq 0 ]]
}


array.toString() {
    local lengthOnly
    local _toStringDelim
    local _toStringQuotes=\"
    local OPTIND=1

    # See os-utils.profile for more info on flag parsing
    while getopts "ld:q:" opt; do
        case "$opt" in
            l)
                lengthOnly=true
                ;;
            d)
                _toStringDelim="$OPTARG"
                ;;
            q)
                _toStringQuotes="$OPTARG"
                ;;
        esac
    done

    shift $(( OPTIND - 1 ))

    local -n _arrToString="$1"
    local _arrToStringLength="$(array.length _arrToString)"
    local _arrToStringQuotes="$_toStringQuotes"
    local _arrToStringCmd='printf "${_arrToStringQuotes}%s${_toStringDelim:-}${_arrToStringQuotes} " "${_arrToString[@]}"'

    if [[ -n "$lengthOnly" ]]; then
        echo "$1 (length=$_arrToStringLength)"
    else
        echo "$1 (length=$_arrToStringLength): $(eval "$_arrToStringCmd")"
    fi
}


array.fromString() {
    local _retArrFromStrName
    local _arrFromDelim="$IFS"
    local OPTIND=1

    while getopts "d:r:" opt; do
        case "$opt" in
            d)
                _arrFromDelim="$OPTARG"
                ;;
            r)
                _retArrFromStrName="$OPTARG"
                ;;
        esac
    done

    shift $(( OPTIND - 1 ))

    local _arrFromStr="$1"

    # Local means we don't overwrite global IFS.
    # Still keep original IFS for the return statements.
    local _arrFromOrigIFS="$IFS"
    local IFS
    # This is tricky; IFS uses ANSI-C quoting (see: https://stackoverflow.com/questions/23235651/how-can-i-do-ansi-c-quoting-of-an-existing-bash-variable)
    #
    # We want the *meaning* of backslash-escaped characters, not their literal
    # characters/text, and want the util function to be used in a simple manner,
    # e.g. `array.fromString -d '\n' 'my string'` rather than `-d $'\n'`
    #
    # To get the meaning in bash, you usually write `$'chars'` e.g. `$'\n'` b/c the
    # `$` interprets escaped chars for their actual meaning.
    # But you can't do that by using the normal `IFS=$"$var"` because nesting
    # `$var` in quotes returns the literal characters and `$$var` actually returns
    # `<PID>var`.
    #
    # Even attempts like `printf (%s|%b) $var` and `echo -ne $var` (with and without
    # quotes around both `$var` and the whole statement) failed due to somehow interpreting
    # them literally.
    #
    # Thus, the only option we have is to escape the standard chars used in IFS definitions
    # and inject `$var` without quotes.
    # Moral of the story: QUOTES MAINTAIN THE LITERAL CHARS
    # unless you put them inside a LITERAL `$'$var'`
    eval IFS=\$\'$_arrFromDelim\'
    # Don't quote it since we've changed IFS. If we did quote it, there would be no
    # more string-splitting b/c it'd all be one string instead of separate strings.
    local _newArrFromStr=($_arrFromStr)
    # Return IFS back to what it was before solely for injecting obtained values back
    # into a separate return array and/or for printing to the console.
    IFS="$_arrFromOrigIFS"

    if [[ -n "$_retArrFromStrName" ]]; then
        local -n _retArrFromStr="$_retArrFromStrName"
        _retArrFromStr=("${_newArrFromStr[@]}")
    else
        echo "${_newArrFromStr[@]}"
    fi
}


array.join() {
    local _stripTrailingDelimiter
    local OPTIND=1

    while getopts "s" opt; do
        case "$opt" in
            s)
                _stripTrailingDelimiter=true
                ;;
        esac
    done

    shift $(( OPTIND - 1 ))


    declare -n _arrJoin="$1"
    declare _joinDelim="$2"

    # Append $_joinDelim at the end of every entry in the array
    declare _joinOutput="`printf "%s$_joinDelim" "${_arrJoin[@]}"`"

    # TODO Maybe check out this alternative (https://stackoverflow.com/a/17841619/5771107),
    # which would help solve the array.filter() error below:
    #
    # Modify IFS and then just print all the args (Note: Must be "$*", cannot be "$@")
    # array.join() { local IFS="$1"; shift; echo "$*"; } # use $_joinDelim instead of $1

    if [[ -n "$_stripTrailingDelimiter" ]]; then
        # Remove final $_joinDelim from last array entry in the generated string,
        # i.e. "array,entries,joined,"  -->  "[...],joined"
        #
        # Must be done in separate call b/c substring removal only works with variables, not with
        # strings themselves, due to the required `${}` portion. So you can't nest other calls in it, e.g.
        # ${"`command`"/%stringToReplace}
        # `${str/%remove}` picks the shortest matching string from the end of the array (see String Manipulation docs).
        _joinOutput="${_joinOutput/%$_joinDelim}"
    fi

    echo "$_joinOutput"
}


array.slice() {
    local isLength
    local _retArrNameSliced
    local OPTIND=1

    # See os-utils.profile for more info on flag parsing
    while getopts "lr:" opt; do
        case "$opt" in
            l)
                isLength=true
                ;;
            r)
                _retArrNameSliced="$OPTARG"
                ;;
        esac
    done

    shift $(( OPTIND - 1 ))

    local -n _arrSlice="$1"
    local _startSlice="$2"
    local _endSlice="$3"

    local _arrLengthOrig="`array.length _arrSlice`"
    local _newArrSliced=()
    local _newArrLengthSliced

    # Bash native slicing:
    #   Positive index values: ${array:start:length}
    #   Negative index values: ${array: start: length}
    # To use negative values, a space is required between `:` and the variable
    #   because `${var:-3}` actually represents a default value,
    #   e.g. `myVar=${otherVal:-7}` represents (pseudo-code) `myVar=otherVal || myVar=7`
    if [[ -z "$_endSlice" ]]; then
        # If no end is specified (regardless of `-l`/length or index), default to the rest of the array
        _newArrLengthSliced="$_arrLengthOrig"
    elif [[ -n "$isLength" ]]; then
        # If specifying length instead of end-index, use native bash array slicing
        _newArrLengthSliced="$(( _endSlice ))"
    else
        # If specifying end-index, use custom slicing based on a range of [start, end):
        if (( _startSlice >=0 )) && (( _endSlice < 0 )); then
            # User is slicing to an arbitrary end point in the array without knowing the length
            _newArrLengthSliced="$(( _arrLengthOrig - _startSlice + _endSlice ))"
        else
            # Normal index selection logic
            _newArrLengthSliced="$(( _endSlice - _startSlice ))"
        fi
    fi

    _newArrSliced=("${_arrSlice[@]: _startSlice: _newArrLengthSliced}")

    if [[ -n "$_retArrNameSliced" ]]; then
        local -n retArr="$_retArrNameSliced"
        retArr=("${_newArrSliced[@]}")
    else
        echo "${_newArrSliced[@]}"
    fi
}


array.filter() {
    local _retArrNameFiltered
    local isRegex
    local OPTIND=1

    while getopts "er:" opt; do
        case "$opt" in
            r)
                _retArrNameFiltered="$OPTARG"
                ;;
            e)
                isRegex=true
                ;;
        esac
    done

    shift $(( OPTIND - 1 ))

    declare -n _arrFilter="$1"
    declare filterQuery="$2"

    declare _newArrFiltered=()


    if [[ -n "$isRegex" ]]; then
        # Do this outside of the loop so that a new `egrep` command isn't
        # instantiated on every entry.
        # Net result is to parse the entire array at once rather than one entry
        # at a time, resulting in a significant speed boost.
        #
        # Slower alternative (orders of magnitude slower):
        #     for entry in "${_arrFilter[@]}"; do
        #         if [[ -n "$isRegex" ]]; then
        #             if echo "$entry" | egrep "$filterQuery" &>/dev/null; then
        #                 # echo "$entry"
        #                 _newArrFiltered+=("$entry")
        #             fi
        #         else
        #             if eval "$filterQuery" 2>/dev/null; then
        #                 _newArrFiltered+=("$entry")
        #             fi
        #         fi
        #     done

        # TODO Will fail with array entries that contain \n
        # TODO Will fail to maintain quoted strings
        # Test:
        # failingNewline=('a
        # 10
        # b' c d 12 f 1)  # filtered (length=5): a b c d f
        # failingSpaces=('a 10 b' c d 12 f 1)  # filtered (length=6): a 10 b c d f
        # source .profile mac_Nextdoor && array.filter -er filtered arr '\D' && array.toString filtered
        #
        # Attempt:
        # local _ifsOrigFilter=$IFS
        # local IFS=$'\n'
        # printf '%s\n' "${arr1[@]}" | egrep '\D' | xargs -0 printf '%s~~'
        _newArrFiltered+=($(printf '%s\n' "${_arrFilter[@]}" | egrep "$filterQuery"))
        # IFS=$_ifsOrigFilter
    else
        # Call using, e.g. `array.filter myArray '[[ "$entry" =~ [a-z] ]]'`
        for entry in "${_arrFilter[@]}"; do
            if eval "$filterQuery" 2>/dev/null; then
                _newArrFiltered+=("$entry")
            fi
        done
    fi


    if [[ -n "$_retArrNameFiltered" ]]; then
        local -n _retArrFiltered="$_retArrNameFiltered"
        _retArrFiltered=("${_newArrFiltered[@]}")
    else
        echo "${_newArrFiltered[@]}"
    fi
}


array.contains() {
    local isRegex
    local OPTIND=1

    while getopts "er:" opt; do
        case "$opt" in
            e)
                isRegex=true
                ;;
        esac
    done

    shift $(( OPTIND - 1 ))


    local -n _arrContains="$1"
    local query="$2"

    # As mentioned in array.empty(), `echo true/false` would work for if-statements.
    # However, if one-lining the function call within a line, then true/false will be echoed to
    # the console. For example, the line below would print 'true/false' unexpectedly:
    # `array.contains myArr 'hello' && cd dir1 || cd dir2`
    # Thus, rely on the standard `return 0/1` for true/false instead of echoing it.
    if [[ -n "$isRegex" ]]; then
        array.filter -er filteredArray _arrContains "$query"

        ! $(array.empty filteredArray) && return
    else
        for entry in "${_arrContains[@]}"; do
            # TODO verify this works
            if [[ "$entry" =~ "$query" ]]; then
                return
            fi
        done
    fi

    return 1
}


array.reverse() {
    local _retArrNameReversed
    local inPlace
    local OPTIND=1

    while getopts "ir:" opt; do
        case "$opt" in
            r)
                _retArrNameReversed="$OPTARG"
                ;;
            i)
                inPlace=true
                ;;
        esac
    done

    shift $(( OPTIND - 1 ))


    declare -n _arrReverse="$1"

    if [[ -n "$inPlace" ]]; then
        declare -n _newArrReversed=_arrReverse
    else
        declare _newArrReversed=()
        for entry in "${_arrReverse[@]}"; do
            _newArrReversed+=("$entry")
        done
    fi

    declare _leftReverse=0
    declare _rightReverse=$(( $(array.length _newArrReversed) - 1 )) # Want index of last entry, not length


    while [[ _leftReverse -lt _rightReverse ]]; do
        # Swap left/right. Works for arrays of both odd & even lengths
        declare _leftValReverse="${_newArrReversed[_leftReverse]}"

        _newArrReversed[$_leftReverse]="${_newArrReversed[_rightReverse]}"
        _newArrReversed[$_rightReverse]="$_leftValReverse"

        (( _leftReverse++, _rightReverse-- ))
    done


    if [[ -n "$_retArrNameReversed" ]]; then
        local -n _retArrReversed="$_retArrNameReversed"
        _retArrReversed=("${_newArrReversed[@]}")
    elif [[ -n "$inPlace" ]]; then
        # Do nothing. `:` is a special keyword in Bash to 'do nothing silently'.
        # Useful for cases like this, where we don't want to execute anything,
        #   but DO want to capture the else-if case.
        :
    else
        echo "${_newArrReversed[@]}"
    fi
}


array.merge() {
    # TODO use array.gen-matrix
    # TODO see if `readarray` would work: https://www.gnu.org/savannah-checkouts/gnu/bash/manual/bash.html#index-mapfile

    local allArrayNames=("$@")
    local allArrayValues=()

    for arrName in ${allArrayNames[@]}; do
        local arrNameToAccessAllValues="$arrName[@]"
        local arrValues=("${!arrNameToAccessAllValues}")

        allArrayValues+=("${arrValues[@]}")
    done

    echo "All vals: $(array.toString allArrayValues)"

    if (( $(array.length arr) == 1 )); then
        echo "${allArrayValues[1][@]}"
    fi

    # TODO return
}


# Manually gets array contents by name (for Bash < 4)
array.values-from-name() {
    # Tried with all of the following, but they all ruined array entries containing spaces
    # local arr=(`array.values-from-name $1`)
    # local arr=("`array.values-from-name $1`")
    # local arr=($(array.values-from-name $1))
    # local arr=("$(array.values-from-name $1)")

    # Could alternatively be done via `[declare|local] -n arr=$1` because `-n` does the
    # indirection/name-ref for us
    local arrName="$1"
    local arrValuesCmd="$1[@]"
    # Indirection in bash is a way of using the passed string as the name of a variable
    # and then reading the value of the string rather than using the string's literal contents.
    # It's somewhat equivalent to how using `eval "$someCmd"` would run e.g. `eval "cd .."`
    # except instead of a command, it's a variable name.
    #
    # In our case, this means we can do array operations given the array name rather than
    # the array variable itself, allowing the *name* to be passed into our array-util functions
    # rather than its contents.
    # e.g.
    # myArr=('a' 'b')
    # echo ${myArr[@]} # 2
    # myArrName='myArr'
    # myArrLength='myArr[@]'
    # echo ${!myArrLength} # 2
    #
    # Exception: `${!name[@]}` expands the keys in an array, int (normal) or string (associative).
    local arrValues=("${!arrValuesCmd}")
    # TODO The below doesn't work b/c `arrName != actualName`
    # local arrKeys=("${!arrName[@]}")
    #
    # for i in "${!arrName[@]}"; do
    #     echo "i: $i"
    # done
    # echo "${arrKeys[@]}"

    # Attempts with all of the above "Tried" usages:
    # echo "${arrValues[@]}"
    # echo "${#arrValues[@]}"
    # echo ${arrValues[*]}
    # echo "${arrValues[*]}"
    # printf "'%s' " "${arrValues[@]}"
    # echo $(printf "'%s' " "${arrValues[@]}")
    # for val in "${arrKeys[@]}"; do
    #     echo "$val"
    # done


    ## Requires the calling parent to know if it should use `declare -a` vs `declare -A`
    ## since `local var="$(array.values-from-name myArr)"` doesn't work.
    ##
    # `declare -p` gets all the data about a variable as if it were created using the current
    # content it contains, regardless of what type it is.
    #
    # e.g.
    # declare -a array=('a' 'b')
    # declare -A map=([x]='a b' [y]='c d')
    # array+=('c')
    # map[z]='e f'
    #
    # declare -p array  # outputs: declare -a array=("a" "b")
    # declare -p map    # outputs: declare -A map=([x]="a b" [y]="c d" [z]="e f")
    local arrDeclarationCmd="`declare -p $arrName`"
    # Strip out the leading content before "=" so that only the variable contents
    # are returned.
    # This way, we can call `declare -[aA] var="$(array.values-from-name myArr)"`
    # to read arrays from input by name.
    local arrDeclarationOnlyArrayContents="${arrDeclarationCmd#*=}" # string substitution - replace /^.*=/ with ''

    # echo "$arrDeclarationCmd" # Returns entire string, which can't be called by `eval` or similar
    echo "$arrDeclarationOnlyArrayContents" # Requires calling parent to know the variable type and to use `declare -[aA]` accordingly
}


array.gen-matrix() {
    local allArrayNames=("$@")
    # `declare -A myAssociativeArray` doesn't work on all systems.
    # However, it's simply meant to declare the type, read/write restrictions, etc.
    # so we can still use associative arrays here.
    local allArrayValues

    # for arrName in ${allArrayNames[@]}; do
    # for i in `seq 0 $(( $(array.length allArrayNames) - 1 ))`; do
    for ((i = 0; i < $(array.length allArrayNames); i++)); do
        local arrName="${allArrayNames[$i]}"
        # echo "arrName (index=$i): $arrName"
        local arrNameToAccessAllValues="$arrName[@]"
        local arrValues=("${!arrNameToAccessAllValues}")

        # allArrayValues[$arrName]=("${arrValues[@]}")
        # allArrayValues[$arrName]="${arrValues[@]}"
        # allArrayValues[$i]=("${arrValues[@]}")
        allArrayValues[$i]=${!arrNameToAccessAllValues}
    done

    echo "All vals: $(array.toString allArrayValues)"
    echo "All keys: ${!allArrayValues[@]}"

    # if [[ $(array.length allArrayNames) -eq 1 ]]; then
        # echo "${allArrayValues[1][@]}" # doesn't work b/c can't nest arrays in arrays
    # fi

    echo -e ""
    # echo "Results (length=${#allArrayValues[@]}): ${allArrayValues[@]}"
    for i in ${!allArrayValues[@]}; do
        # local entryLength=${#allArrayValues[$i][@]}
        local entryLength=${#allArrayValues[$i][@]}
        local entryValue=${allArrayValues[$i]}
        echo "Index [$i] (length=$entryLength): $entryValue"
        echo "Val[0] = ${entryValue[0]}"
        echo "Val[1] = ${entryValue[1]}"
        echo "Val[2] = ${entryValue[2]}"
    done

    # for arrVal in ${allArrayValues[@]}; do
    #     echo "arrVal ($arrVal): ${allArrayValues[$arrVal]}"
    # done

    # TODO return
}



### Tests and examples ###

# _testSlice() {
#     myArray=(x y 'a b c' z 5 14)   # length=6
#
#     array.slice myArray 2 4
#     # > a b c z
#
#     array.slice -l myArray 3 2
#     # > z 5
#
#     # Note: Output was manually quoted to show the result more clearly.
#     # Actual stdout content won't contain those quotes, which is
#     #   why the `-r returnArray` option was added.
#     array.slice -r slicedArray myArray -5 -3   # equivalent of [2, 4)
#     # > (null)
#     echo -e "myArray (length=${#myArray[@]}): ${myArray[@]} \nslicedArray (length=${#slicedArray[@]}): ${slicedArray[@]}"
#     # > myArray (length=6): x y 'a b c' z 5 14
#     # > slicedArray (length=2): 'a b c' z
#
#     array.slice -lr slicedArray myArray -5 3   # length instead of index, equivalent of [2, 5)
#     # > (null)
#     echo -e "myArray (length=${#myArray[@]}): ${myArray[@]} \nslicedArray (length=${#slicedArray[@]}): ${slicedArray[@]}"
#     # > myArray (length=6): x y 'a b c' z 5 14
#     # > slicedArray (length=3): 'a b c' z 5
# } && _testSlice
