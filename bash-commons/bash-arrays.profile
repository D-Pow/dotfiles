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

array.toString() {
    local lengthOnly
    local OPTIND=1

    # See os-utils.profile for more info on flag parsing
    while getopts "l" opt; do
        case "$opt" in
            l)
                lengthOnly=true
                ;;
        esac
    done

    shift $(( OPTIND - 1 ))

    local -n arr="$1"

    if [[ -n "$lengthOnly" ]]; then
        echo "$1 (length=${#arr[@]})"
    else
        echo "$1 (length=${#arr[@]}): ${arr[@]}"
    fi
}


array.length() {
    local -n arr="$1"

    echo ${#arr[@]}
}


array.empty() {
    local length=`array.length $1`

    # Want to be able to use this like `if array.empty myArr; then ...`
    # Options on how to do this:
    #
    # Manually echo true/false. echo is required to return value from a function if in one-liner,
    # but isn't required if "calling" the command directly.
    # `[[ $length -eq 0 ]] && echo true || echo false`
    #
    # Replace `echo` with "calling" the command directly.
    # if [[ $length -eq 0 ]]; then
    #     true
    # else
    #     false
    # fi
    #
    # Or, simply run the check in-place.
    [[ $length -eq 0 ]]
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
    local retArrName
    local OPTIND=1

    # See os-utils.profile for more info on flag parsing
    while getopts "lr:" opt; do
        case "$opt" in
            l)
                isLength=true
                ;;
            r)
                retArrName="$OPTARG"
                ;;
        esac
    done

    shift $(( OPTIND - 1 ))

    # Can't use the same variable name, `arr`, multiple times
    # so call `array.length $1` instead of `array.length arr`
    local arrLength="`array.length $1`"
    local -n arr="$1"
    local start="$2"
    local end="$3"

    local newArr=()
    local newArrLength

    # Bash native slicing:
    #   Positive index values: ${array:start:length}
    #   Negative index values: ${array: start: length}
    # To use negative values, a space is required between `:` and the variable
    #   because `${var:-3}` actually represents a default value,
    #   e.g. `myVar=${otherVal:-7}` represents (pseudo-code) `myVar=otherVal || myVar=7`
    if [[ -z "$end" ]]; then
        # If no end is specified (regardless of `-l`/length or index), default to the rest of the array
        newArrLength="$arrLength"
    elif [[ -n "$isLength" ]]; then
        # If specifying length instead of end-index, use native bash array slicing
        newArrLength="$(( end ))"
    else
        # If specifying end-index, use custom slicing based on a range of [start, end):
        #   length == end - start
        newArrLength="$(( end - start ))"
    fi

    newArr=("${arr[@]: start: newArrLength}")

    if [[ -n "$retArrName" ]]; then
        local -n retArr="$retArrName"
        retArr=("${newArr[@]}")
    else
        echo "${newArr[@]}"
    fi
}


array.filter() {
    local retArrName
    local isRegex
    local OPTIND=1

    while getopts "er:" opt; do
        case "$opt" in
            r)
                retArrName="$OPTARG"
                ;;
            e)
                isRegex=true
                ;;
        esac
    done

    shift $(( OPTIND - 1 ))

    declare -n arr="$1"
    declare filterQuery="$2"

    declare newArr=()


    if [[ -n "$isRegex" ]]; then
        # Do this outside of the loop so that a new `egrep` command isn't
        # instantiated on every entry.
        # Net result is to parse the entire array at once rather than one entry
        # at a time, resulting in a significant speed boost.
        #
        # Slower alternative (orders of magnitude slower):
        #     for entry in "${arr[@]}"; do
        #         if [[ -n "$isRegex" ]]; then
        #             if echo "$entry" | egrep "$filterQuery" &>/dev/null; then
        #                 # echo "$entry"
        #                 newArr+=("$entry")
        #             fi
        #         else
        #             if eval "$filterQuery" 2>/dev/null; then
        #                 newArr+=("$entry")
        #             fi
        #         fi
        #     done
        newArr+=($(array.join arr '%s\n' | egrep "$filterQuery"))
    else
        # Call using, e.g. `array.filter myArray '[[ "$entry" =~ [a-z] ]]'`
        for entry in "${arr[@]}"; do
            if eval "$filterQuery" 2>/dev/null; then
                newArr+=("$entry")
            fi
        done
    fi


    if [[ -n "$retArrName" ]]; then
        local -n retArr="$retArrName"
        retArr=("${newArr[@]}")
    else
        echo "${newArr[@]}"
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
            if [[ "$entry" =~ "$query" ]]; then
                return
            fi
        done
    fi

    return 1
}


array.reverse() {
    local retArrName
    local inPlace
    local OPTIND=1

    while getopts "ir:" opt; do
        case "$opt" in
            r)
                retArrName="$OPTARG"
                ;;
            i)
                inPlace=true
                ;;
        esac
    done

    shift $(( OPTIND - 1 ))


    declare -n arr="$1"

    if [[ -n "$inPlace" ]]; then
        declare -n newArr=arr
    else
        declare newArr=()
        for entry in "${arr[@]}"; do
            newArr+=("$entry")
        done
    fi

    declare left=0
    declare right=$(( ${#newArr[@]} - 1 )) # Want index of last entry, not length


    while [[ left -lt right ]]; do
        # Swap left/right. Works for arrays of both odd & even lengths
        declare leftVal="${newArr[left]}"

        newArr[$left]="${newArr[right]}"
        newArr[$right]="$leftVal"

        (( left++, right-- ))
    done


    if [[ -n "$retArrName" ]]; then
        local -n retArr="$retArrName"
        retArr=("${newArr[@]}")
    elif [[ -n "$inPlace" ]]; then
        # Do nothing. `:` is a special keyword in Bash to 'do nothing silently'.
        # Useful for cases like this, where we don't want to execute anything,
        #   but DO want to capture the else-if case.
        :
    else
        echo "${newArr[@]}"
    fi
}


array.merge() {
    # TODO use array.gen-matrix

    local allArrayNames=("$@")
    local allArrayValues=()

    for arrName in ${allArrayNames[@]}; do
        local arrNameToAccessAllValues="$arrName[@]"
        local arrValues=("${!arrNameToAccessAllValues}")

        allArrayValues+=("${arrValues[@]}")
    done

    echo "All vals (length=${#allArrayValues[@]}): ${allArrayValues[@]}"

    if [[ ${#allArrayNames[@]} -eq 1 ]]; then
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
    # for i in `seq 0 $((${#allArrayNames[@]} - 1))`; do
    for ((i = 0; i < ${#allArrayNames[@]}; i++)); do
        local arrName="${allArrayNames[$i]}"
        # echo "arrName (index=$i): $arrName"
        local arrNameToAccessAllValues="$arrName[@]"
        local arrValues=("${!arrNameToAccessAllValues}")

        # allArrayValues[$arrName]=("${arrValues[@]}")
        # allArrayValues[$arrName]="${arrValues[@]}"
        # allArrayValues[$i]=("${arrValues[@]}")
        allArrayValues[$i]=${!arrNameToAccessAllValues}
    done

    echo "All vals (length=${#allArrayValues[@]}): ${allArrayValues[@]}"
    echo "All keys: ${!allArrayValues[@]}"

    # if [[ ${#allArrayNames[@]} -eq 1 ]]; then
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
