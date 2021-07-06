arrLength() {
    # TODO use arrValuesFromName
    # since `-n` isn't supported on Bash < 4 (i.e. Mac without Brew's Bash)
    local -n arr=$1

    echo ${#arr[@]}
}


arrEmpty() {
    local -n arr=$1
    local length=`arrLength $1`

    # Want to be able to use this like `if arrEmpty myArr; then ...`
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


arrContains() {
    local query="$1"
    local -n arr=$2

    # As mentioned above, `echo true/false` would work for if-statements.
    # However, if one-lining the function call within a line, then true/false will be echoed to
    # the console. For example, the line below would print 'true/false' unexpectedly:
    # `arrContains 'hello' myArr && cd dir1 || cd dir2`
    # Thus, rely on the standard `return 0/1` for true/false instead of echoing it.
    for entry in "${arr[@]}"; do
        if [[ "$entry" = "$query" ]]; then
            return 0
        fi
    done

    return 1
}


arrMergeArrays() {
    # TODO use arrGenerateMatrixFromArrays

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


arrValuesFromName() {
    # Tried with all of the following, but they all ruined array entries containing spaces
    # local arr=(`arrValuesFromName $1`)
    # local arr=("`arrValuesFromName $1`")
    # local arr=($(arrValuesFromName $1))
    # local arr=("$(arrValuesFromName $1)")

    # Could alternatively be done via `local -n arr=$1` because `-n` does the
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

    # Attempts with all of the above "Tried" usages:
    # echo "${arrValues[@]}"
    # echo "${#arrValues[@]}"
    # echo ${arrValues[*]}
    # printf "'%s' " "${arrValues[@]}"
    # echo $(printf "'%s' " "${arrValues[@]}")
    for val in "${arrValues[@]}"; do
        echo "$val"
    done
}


arrGenerateMatrixFromArrays() {
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
