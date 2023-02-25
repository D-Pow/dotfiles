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

array.isArray() {
    # Don't need nameref since we need to use `declare -p origName`
    # Otherwise, we'd have to use dereferencing `declare -p "${!_isArrayArr}`
    declare _isArrayArr="$1"

    # If arg is a nameref, we need to check the value of the arg pointer, not the arg itself
    if (( $(declare -p "$_isArrayArr" 2>/dev/null | grep -c "declare \-n") >= 1)); then
        declare -n _isArrayArrRef="$_isArrayArr"

        _isArrayArr="${!_isArrayArrRef}"  # returns the name of the nameref
    fi

    # `grep -c` = Count number of matching lines
    # `declare -a` = Arrays, `declare -A` = Associative arrays
    # We can still send `declare -p` errors to null b/c grep count will be 0
    (( $(declare -p "$_isArrayArr" 2>/dev/null | grep -ic "declare \-a") >= 1 ))
}


array.keys() {
    # Docs: https://www.gnu.org/savannah-checkouts/gnu/bash/manual/bash.html#:~:text=a%20separate%20word.-,%24%7B!name%5B%40%5D%7D,-%24%7B!name%5B*%5D%7D
    declare _retArrKeysName
    declare OPTIND=1

    while getopts "r:" opt; do
        case "$opt" in
            r)
                _retArrKeysName="$OPTARG"
                ;;
        esac
    done

    shift $(( OPTIND - 1 ))


    declare -n _arrKeysArr="$1"
    declare _arrKeys=("${!_arrKeysArr[@]}") # Quotes to preserve spaces in associative arrays' keys


    if [[ -n "$_retArrKeysName" ]]; then
        declare -n _retArrKeys="$_retArrKeysName"

        _retArrKeys=("${_arrKeys[@]}")
    else
        echo "${_arrKeys[@]}"
    fi
}


array.length() {
    declare -n _arrLengthArr="$1"
    declare _arrLength=${#_arrLengthArr[@]}

    if (( _arrLength == 1 )) && [[ "${_arrLengthArr[@]}" == '' ]]; then
        echo 0
    else
        echo $_arrLength
    fi
}


array.empty() {
    declare _lengthEmpty=`array.length $1`

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
    declare lengthOnly
    declare _toStringDelim
    declare _toStringQuotes=\"
    declare _entriesOnly
    declare OPTIND=1

    # See os-utils.profile for more info on flag parsing
    while getopts "eld:q:" opt; do
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
            e)
                _entriesOnly=true
                ;;
        esac
    done

    shift $(( OPTIND - 1 ))

    declare -n _arrToString="$1"
    declare _arrToStringLength="$(array.length _arrToString)"
    declare _arrToStringQuotes="$_toStringQuotes"
    declare _arrToStringEntries="$(printf "${_arrToStringQuotes}%s${_toStringDelim:-}${_arrToStringQuotes} " "${_arrToString[@]}")"

    if [[ -n "$_entriesOnly" ]]; then
        echo -e "$_arrToStringEntries"
    elif [[ -n "$lengthOnly" ]]; then
        echo "$1 (length=$_arrToStringLength)"
    else
        # Prefix for stringified array
        echo -n "$1 (length=$_arrToStringLength): "

        if declare -p "$1" | egrep -q '^(declare|local) -A'; then
            # Print matrix keys as well
            # Quoting is taken care of automatically with matrices in `declare -p`
            declare -p "$1" | esed 's/^[^=]+=(.*)$/\1/; s/(^\()|(\s*\)$)//g'
        else
            echo "$_arrToStringEntries"
        fi
    fi
}


array.fromString() {
    declare _retArrFromStrName
    declare _arrFromDelim="$IFS"
    declare OPTIND=1

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

    declare _arrFromStr="$1"

    # Local means we don't overwrite global IFS.
    # Still keep original IFS for the return statements.
    declare _arrFromOrigIFS="$IFS"
    declare IFS
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
    declare _newArrFromStr=($_arrFromStr)
    # Return IFS back to what it was before solely for injecting obtained values back
    # into a separate return array and/or for printing to the console.
    IFS="$_arrFromOrigIFS"

    if [[ -n "$_retArrFromStrName" ]]; then
        declare -n _retArrFromStr="$_retArrFromStrName"
        _retArrFromStr=("${_newArrFromStr[@]}")
    else
        echo "${_newArrFromStr[@]}"
    fi
}


array.join() {
    declare _stripTrailingDelimiter
    declare OPTIND=1

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
    declare isLength
    declare _retArrNameSliced
    declare OPTIND=1

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

    declare -n _arrSlice="$1"
    declare _startSlice="$2"
    declare _endSlice="$3"

    declare _arrLengthOrig="`array.length _arrSlice`"
    declare _newArrSliced=()
    declare _newArrLengthSliced

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
        declare -n retArr="$_retArrNameSliced"
        retArr=("${_newArrSliced[@]}")
    else
        echo "${_newArrSliced[@]}"
    fi
}


array.indexOf() {
    declare -n _arrIndexOfArr="$1"
    declare _arrIndexOfQuery="$2"

    declare _arrIndexOfArrIndex
    for _arrIndexOfArrIndex in "${!_arrIndexOfArr[@]}"; do
        declare _arrIndexOfEntry="${_arrIndexOfArr[_arrIndexOfArrIndex]}"

        if [[ "$_arrIndexOfEntry" == "$_arrIndexOfQuery" ]]; then
            echo "$_arrIndexOfArrIndex"

            return
        fi
    done

    return 1
}


array.filter() {
    declare _retArrNameFiltered
    declare _filterIsEval
    declare OPTIND=1

    while getopts "er:" opt; do
        case "$opt" in
            r)
                _retArrNameFiltered="$OPTARG"
                ;;
            e)
                _filterIsEval=true
                ;;
        esac
    done

    shift $(( OPTIND - 1 ))

    declare -n _arrFilter="$1"
    declare _arrFilterQuery="$2"


    declare _newArrFiltered=()
    declare _arrFilterEntry

    for _arrFilterEntry in "${_arrFilter[@]}"; do
        if [[ -n "$_filterIsEval" ]]; then
            # Call using, e.g. `array.filter myArray '[[ "$_arrFilterEntry" =~ [a-z] ]]'`
            if eval "$_arrFilterQuery" 2>/dev/null; then
                _newArrFiltered+=("$_arrFilterEntry")
            fi
        else
            # Note: Doing this outside a loop would make it much faster since a new
            # `egrep` command isn't instantiated on every entry.
            #
            # e.g.
            #   declare IFS=$'\n'
            #   _newArrFiltered+=($(printf '%s\n' "${_arrFilter[@]}" | egrep "$_arrFilterQuery"))
            #   # Another attempt
            #   printf '%s\n' "${arr1[@]}" | egrep '\D' | xargs -0 printf '%s~~'
            #
            # The net result of that would be to parse the entire array at once rather than one entry
            # at a time, resulting in a significant speed boost, but reducing its entry-parsing
            # capabilities, e.g. doing so makes it inaccurate against array entries that contain
            # newlines and splits each line into separate return-array entries, each of which would
            # be tested against.
            if echo "$_arrFilterEntry" | egrep -q "$_arrFilterQuery"; then
                _newArrFiltered+=("$_arrFilterEntry")
            fi
        fi
    done


    if [[ -n "$_retArrNameFiltered" ]]; then
        declare -n _retArrFiltered="$_retArrNameFiltered"
        _retArrFiltered=("${_newArrFiltered[@]}")
    else
        echo "${_newArrFiltered[@]}"
    fi
}


array.contains() {
    declare _arrContainsIsEval
    declare OPTIND=1

    while getopts "e" opt; do
        case "$opt" in
            e)
                _arrContainsIsEval=true
                ;;
        esac
    done

    shift $(( OPTIND - 1 ))


    declare -n _arrContains="$1"
    declare query="$2"

    # As mentioned in array.empty(), `echo true/false` would work for if-statements.
    # However, if one-lining the function call within a line, then true/false will be echoed to
    # the console. For example, the line below would print 'true/false' unexpectedly:
    # `array.contains myArr 'hello' && cd dir1 || cd dir2`
    # Thus, rely on the standard `return 0/1` for true/false instead of echoing it.
    declare _arrContainsFilteredArray

    array.filter ${_arrContainsIsEval:+-e} -r _arrContainsFilteredArray _arrContains "$query"

    ! $(array.empty _arrContainsFilteredArray) && return

    return 1
}


array.map() {
    declare _arrMapRetArrName
    declare _arrMapNoPreserveSpaces
    declare -A optsConfig=(
        ['r:,_arrMapRetArrName']='Array in which to store resulting transformed entries'
        ['s|no-preserve-spaces,_arrMapNoPreserveSpaces']="Don't preserve spaces in mapped output array"
    )
    declare argsArray

    parseArgs optsConfig "$@"
    (( $? )) && return 1

    declare -n _arrMapArrOrig="${argsArray[0]}"
    declare _arrMapCmd="${argsArray[1]}"

    # If return array name passed, then add `-n` nameref option.
    # Otherwise, leave it blank to avoid "Error: '' not a valid variable name."
    # Note: Cannot wrap it in quotes because then it's read as an argument instead of an option.
    # Simpler than having two separate arrays (one for internal usage and one
    # nested in an if-statement at the end of the function to declare a nameref
    # variable for the returned array).
    declare ${_arrMapRetArrName:+-n} _arrMapRetArr="$_arrMapRetArrName"

    if array.empty _arrMapRetArr || ! array.isArray _arrMapRetArr; then
        _arrMapRetArr=()
    fi

    if [[ -z "$_arrMapCmd" ]]; then
        # If no command string given through args, then read it from stdin (`read` automatically chooses stdin).
        # `-r` = Read string values as-is (e.g. backslash doesn't escape characters).
        # `-d ''` = Set delimiter to empty (null) string so newlines can be accepted.
        #
        # e.g.
        #   array.map arr <<- 'EOF'
        #       entryLength=${#value}
        #       echo "Cost of key: $key = $(( entryLength + 100 ))"
        #   EOF
        read -r -d '' _arrMapCmd
    fi


    declare key
    for key in "${!_arrMapArrOrig[@]}"; do
        declare value="${_arrMapArrOrig[$key]}"

        if [[ -n "$_arrMapNoPreserveSpaces" ]]; then
            _arrMapRetArr+=($(eval "$_arrMapCmd"))
        else
            _arrMapRetArr+=("$(eval "$_arrMapCmd")")
        fi
    done


    if [[ -z "$_arrMapRetArrName" ]]; then
        echo "${_arrMapRetArr[@]}"
    fi
}


array.reverse() {
    declare _retArrNameReversed
    declare inPlace
    declare OPTIND=1

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
        declare -n _retArrReversed="$_retArrNameReversed"
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

    declare allArrayNames=("$@")
    declare allArrayValues=()

    for arrName in ${allArrayNames[@]}; do
        declare arrNameToAccessAllValues="$arrName[@]"
        declare arrValues=("${!arrNameToAccessAllValues}")

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
    declare arrName="$1"
    declare arrValuesCmd="$1[@]"
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
    declare arrValues=("${!arrValuesCmd}")
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
    declare arrDeclarationCmd="`declare -p $arrName`"
    # Strip out the leading content before "=" so that only the variable contents
    # are returned.
    # This way, we can call `declare -[aA] var="$(array.values-from-name myArr)"`
    # to read arrays from input by name.
    declare arrDeclarationOnlyArrayContents="${arrDeclarationCmd#*=}" # string substitution - replace /^.*=/ with ''

    # echo "$arrDeclarationCmd" # Returns entire string, which can't be called by `eval` or similar
    echo "$arrDeclarationOnlyArrayContents" # Requires calling parent to know the variable type and to use `declare -[aA]` accordingly
}


array.gen-matrix() {
    declare allArrayNames=("$@")
    # `declare -A myAssociativeArray` doesn't work on all systems.
    # However, it's simply meant to declare the type, read/write restrictions, etc.
    # so we can still use associative arrays here.
    declare allArrayValues

    # for arrName in ${allArrayNames[@]}; do
    # for i in `seq 0 $(( $(array.length allArrayNames) - 1 ))`; do
    for ((i = 0; i < $(array.length allArrayNames); i++)); do
        declare arrName="${allArrayNames[$i]}"
        # echo "arrName (index=$i): $arrName"
        declare arrNameToAccessAllValues="$arrName[@]"
        declare arrValues=("${!arrNameToAccessAllValues}")

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
        declare entryLength=${#allArrayValues[$i][@]}
        declare entryValue=${allArrayValues[$i]}
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
