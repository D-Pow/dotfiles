npms() {
    # regex is homemade ~/bin/regex python script
    regex '"scripts": [^\}]*\}' ./package.json
}

alias npmr='npm run'
alias npmrtf="npm run test 2>&1 | egrep -o '^FAIL.*'" # only print filenames of suites that failed
alias npmPackagesWithVulns="npm audit | grep 'Dependency of' | sort -u | egrep -o '\S+(?=\s\[\w+\])'"


export NVM_DIR="$HOME/.nvm"
# Load nvm
[ -s "$NVM_DIR/nvm.sh" ] && source "$NVM_DIR/nvm.sh"
# Load nvm bash_completion
[ -s "$NVM_DIR/bash_completion" ] && source "$NVM_DIR/bash_completion"
export NVM_SYMLINK_CURRENT=true # Makes a symlink at ~/.nvm/current/bin/node so you don't have to chage IDEs' configurations when changing node versions



### Docker ###

dockerFindByName() {
    local imageName="$1"

    shift

    echo "`docker ps -a "$@" --filter "name=$imageName"`"
}

dockerIsContainerRunning() {
    local imageId="`dockerFindByName "$1" -q`"

    docker inspect --format '{{json .State.Running}}' "$imageId"
}

dockerGetLogs() {
    local _dockerLogOutputFile
    local _dockerContainerName
    local OPTIND=1

    while getopts "o:n:" opt; do
        case "$opt" in
            o)
                _dockerLogOutputFile="$OPTARG"
                ;;
            n)
                _dockerContainerName="$OPTARG"
                ;;
            *)
                local _passedArg="${!OPTIND}"

                if [[ "$_passedArg" =~ --[a-zA-Z0-9] ]]; then  # String comparison regex (simple bash regex) cannot be quoted
                    local _errMsg=

                    _errMsg+='Please add "--" in between args to this function vs args forwarded to `docker logs`.'
                    _errMsg+='e.g. dockerGetLogs -n myContainerName -- --since 10m'

                    echo "$_errMsg" >&2

                    return 1
                fi
                ;;
        esac
    done

    shift $(( OPTIND - 1 ))

    # Run the following in a subshell so that the output redirection doesn't affect the calling parent.
    # Wouldn't be necessary if this were defined in a separate script; as a .profile, its parent is the live shell.
    (
    if [[ -n "$_dockerLogOutputFile" ]]; then
        # TODO If you want to output to multiple files (e.g. one for each container), then use `tee`.
        # Starter example: https://stackoverflow.com/questions/876239/how-to-redirect-and-append-both-stdout-and-stderr-to-a-file-with-bash/66950971#66950971
        exec 1>>"$_dockerLogOutputFile"
        exec 2>&1
    fi

    for containerName in $(dockerFindByName "$_dockerContainerName" --format '{{.Names}}'); do
        echo "Container: $containerName"
        docker logs "$@" "$containerName" >&1
        echo -e '\n\n----------------------------------------------------\n\n'
    done

    if [[ -n "$_dockerLogOutputFile" ]]; then
        echo "Docker logs written to '$_dockerLogOutputFile'"
    fi
    )
}
