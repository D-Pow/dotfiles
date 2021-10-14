npms() {
    # regex is homemade ~/bin/regex python script
    regex '"scripts": [^\}]*\}' ./package.json
}

# By default, allow ES modules, importing JSON, top-level await, and other relevant/useful features
# See: https://nodejs.org/api/cli.html#cli_node_options_options
NODE_OPTIONS='--experimental-modules --experimental-json-modules --experimental-top-level-await --experimental-import-meta-resolve'

npmvalidatePackageLockResolvedUrls() {
    declare _nonNpmRegistryPackages="$(cat package-lock.json \
        | egrep -i '^\s*"resolved":' \
        | grep -v 'resolved": "https://registry.npmjs.org'
    )"

    if [[ -n "$_nonNpmRegistryPackages" ]]; then
        echo "$_nonNpmRegistryPackages"
        return 1
    fi
}

alias npmrtf="npm run test 2>&1 | egrep -o '^FAIL.*'" # only print filenames of suites that failed
alias npmPackagesWithVulns="npm audit | grep 'Dependency of' | sort -u | egrep -o '\S+(?=\s\[\w+\])'"
npmr() {
    npm run "$@"
}
_autocompleteNpmr() {
    local lastCommandWordIndex=$COMP_CWORD
    local commandWords="${COMP_WORDS[@]}"
    local currentWord="${COMP_WORDS[COMP_CWORD]}"

    # Don't show suggestions if the first arg has already been autocompleted.
    if (( $lastCommandWordIndex > 1 )); then
        return 0
    fi

    # `npm run` will display something akin to the format below,
    # so select only lines starting with two spaces, remove blank lines, and then remove preceding spaces.
    #
    # Life-cycle scripts included in my-app@1.2.3:
    #   start
    #     webpack serve --config ./config/webpack.config.mjs
    # available via `npm run-script`:
    #   build
    #     cross-env NODE_ENV=production webpack --mode production --config ./config/webpack.config.mjs
    local availableCommands="$(npm run | egrep -o '^  \S*' | egrep -v '^\s*$' | sed -E 's|\s||g')"
    local commandsMatchingUserInput="$(echo "$availableCommands" | egrep "^$currentWord")"

    COMPREPLY=($(compgen -W "$commandsMatchingUserInput"))

    return 0
} && complete -F _autocompleteNpmr -o default "npmr" # default shell autocomplete for dirs/files via `-o default`.


export NVM_DIR="$HOME/.nvm"
export NVM_CURRENT_HOME="$HOME/.nvm/current"
# Load nvm
[ -s "$NVM_DIR/nvm.sh" ] && source "$NVM_DIR/nvm.sh"
# Load nvm bash_completion
[ -s "$NVM_DIR/bash_completion" ] && source "$NVM_DIR/bash_completion"
export NVM_SYMLINK_CURRENT=true # Makes a symlink at ~/.nvm/current/bin/node so you don't have to chage IDEs' configurations when changing node versions
export PATH="$NVM_CURRENT_HOME/bin:$PATH"



pipsearch() {
    if [[ -z "$1" ]]; then
        declare USAGE="Searches pypi.org for packages matching the search query (only the first page).
    Created due to \`pip search\` being deprecated.
    \`pip_search\` is a better tool for the job, this is only a quick hack.

    Usage: ${FUNCNAME[0]} packageName"

        echo "$USAGE"
        return 1
    fi

    declare query="$1"
    # -print == -eval 'console.log($command)'
    declare urlQueryParam="$(node -p "encodeURIComponent('$query')")"
    # -silent to hide progress, -Showerrors to show errors even in silent mode
    declare searchHtml="$(curl -sS "https://pypi.org/search/?q=$urlQueryParam")"

    declare packageNamesAndVersions=($(echo "$searchHtml" | egrep -o '(?<=package-snippet__name">|package-snippet__version">).*(?=</span>)'))
    declare searchResult=

    for searchResult in "${!packageNamesAndVersions[@]}"; do
        if (( searchResult % 2 == 0 )); then
            declare packageName="${packageNamesAndVersions[searchResult]}"
            declare packageVersion="${packageNamesAndVersions[(( $searchResult+1 ))]}"

            echo "$packageName@$packageVersion"
        fi
    done
}



### Docker ###

dockerFindContainer() {
    # Enhanced `docker ps` that filters by any field instead of only by name, ID, image, etc.
    # and allows regex queries.
    # Docs: https://docs.docker.com/engine/reference/commandline/ps
    local _dockerPsArgs=("$@")
    local _dockerPsOpts
    local _dockerPsQueryArray

    # All args before the last one
    array.slice -r _dockerPsOpts _dockerPsArgs 0 -1
    # Last arg is image name query string
    array.slice -r _dockerPsQueryArray _dockerPsArgs -1

    local _dockerPsQuery="${_dockerPsQueryArray[0]}"

    # First, get matching results based on any search query (container ID, image, container name, etc.).
    # Then, apply the user's search criteria to the matches afterwards.
    # This is required first because:
    #   Calling `grep` after the user's `ps` options might result in 0 results (e.g. `docker ps -q` removes filtering based on image).
    #   Calling `grep` before `ps` options means we have to parse out the options manually (e.g. `docker ps -q` means we'd have to use `cut` to get only the first column).
    # Also, calling `docker ps` a second time with the user's `ps` options means we can let docker
    # handle the header output itself, too.
    # To call it a second time, remove the headers from this initial filter call so it doesn't
    # interfere with the second call.
    local _dockerPsMatches="$(docker ps -a | egrep -iv 'CONTAINER\s*ID\s*IMAGE' | egrep -i "$_dockerPsQuery")"

    if [[ -z "$_dockerPsMatches" ]]; then
        return 1
    fi

    # Get only the container IDs so we can add our own custom `--filter` query to the `ps` options.
    # Works with any other option, including other `--filter` entries, `-q`, etc.
    local _dockerPsMatchesContainerIds=($(echo "$_dockerPsMatches" | cut -d ' ' -f 1))

    for _containerId in "${_dockerPsMatchesContainerIds[@]}"; do
        _dockerPsOpts+=('--filter' "id=$_containerId")
    done

    docker ps -a "${_dockerPsOpts[@]}"
}

dockerIsContainerRunning() {
    local imageId="`dockerFindContainer -q "$1"`"

    docker inspect --format '{{json .State.Running}}' "$imageId" 2>/dev/null
}

dockerStartContainer() {
    declare _dockerStartContainerArgs=("$@")
    declare _dockerStartContainerOpts
    declare _dockerStartContainerNameArr

    # All args before the last one
    array.slice -r _dockerStartContainerOpts _dockerStartContainerArgs 0 -1
    # Last arg is image name query string
    array.slice -r _dockerStartContainerNameArr _dockerStartContainerArgs -1

    declare _dockerStartContainerName="${_dockerStartContainerNameArr[0]}"

    if [[ -z "$_dockerStartContainerName" ]]; then
        echo 'Please specify a container. Add `-ai` to make container interactive.'
        return 1
    fi

    declare _containerIdIfArgId="$(docker ps -aq | grep "$_dockerStartContainerName")"
    declare _containerIdIfArgName="$(dockerFindContainer -q "$_dockerStartContainerName")"

    declare _dockerStartContainerId="${_containerIdIfArgId:-$_containerIdIfArgName}"

    docker start "${_dockerStartContainerOpts}" "$_dockerStartContainerId"
}

dockerKillAll() {
    docker stop $(docker container ls -q)
}

dockerContainerStatus() {
    declare _dockerContainerStatusQuery="${1:-.}"

    dockerFindContainer --format '{{.State}} - {{.Names}}' "$_dockerContainerStatusQuery" | sort
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

    for containerName in $(dockerFindContainer --format '{{.Names}}' "$_dockerContainerName"); do
        echo "Container: $containerName"
        docker logs "$@" "$containerName" >&1
        echo -e '\n\n----------------------------------------------------\n\n'
    done

    if [[ -n "$_dockerLogOutputFile" ]]; then
        echo "Docker logs written to '$_dockerLogOutputFile'"
    fi
    )
}
