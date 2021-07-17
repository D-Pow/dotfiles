# TODO: Review diff between $* and $@ (applies to arrays): https://stackoverflow.com/questions/12314451/accessing-bash-command-line-args-vs

array.length() {
    # TODO use array.values-from-name
    # since `-n` isn't supported on Bash < 4 (i.e. Mac without Brew's Bash)
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


array.contains() {
    local -n arr="$1"
    local query="$2"

    # As mentioned above, `echo true/false` would work for if-statements.
    # However, if one-lining the function call within a line, then true/false will be echoed to
    # the console. For example, the line below would print 'true/false' unexpectedly:
    # `array.contains myArr 'hello' && cd dir1 || cd dir2`
    # Thus, rely on the standard `return 0/1` for true/false instead of echoing it.
    for entry in "${arr[@]}"; do
        if [[ "$entry" = "$query" ]]; then
            return 0
        fi
    done

    return 1
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
