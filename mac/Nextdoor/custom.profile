_nextdoorRoot="${NEXTDOOR_ROOT:-$HOME/src/nextdoor.com}"



_removePythonSymlinksAndAliases() {
    # Ensure Conda python executables are used instead of Linux's symlinks
    # or aliases from top-level Mac .profile

    declare pythonAlias
    for pythonAlias in $(compgen -a python); do
        unalias "$pythonAlias" &>/dev/null
    done

    declare pythonSymlink
    for pythonSymlink in $(find "$dotfilesDir/linux/bin" -iname 'python*'); do
        # Delete and assume-unchanged in git
        rm -f "$pythonSymlink"
        gau "$pythonSymlink" &>/dev/null # Ignore errors caused by being in a different dir than dotfiles/
    done
} && _removePythonSymlinksAndAliases



alias fe="cd $_nextdoorRoot/apps/nextdoor/frontend"
alias fenext="cd $_nextdoorRoot/services/client-web"


startAllNextdoorDockerContainers() {
    docker-compose -f "${_nextdoorRoot}/docker-compose.yml" up -d
}

stopAllNextdoorDockerContainers() {
    # Since containers are started with `docker-compose`, killing them off one-by-one
    # via `dockerKillAll` could cause some of them to get stuck, e.g. if containers have
    # dependencies on other containers.
    # Avoid that by using the same start/stop commands.
    docker-compose -f "${_nextdoorRoot}/docker-compose.yml" stop
}


export testUserLogins=(
    iceweasel@example.com
    edith@example.com
    jackdohn@example.com
    mieshareed@example.com
    terrancejean@example.com
)
export testUserPassword="abcdef"

alias db-start-server='nd dev getdb'
alias db-login='psql nextdoor django1'

alias fix-sockets='nd dev update unix_socket_bridge'
alias fix-aws='aws_eng_login'

fixcreds() {
    declare _forceFixAws=
    declare _forceFixSockets=
    declare OPTIND=1

    while getopts "asb" opt; do
        case "$opt" in
            a)
                _forceFixAws=true
                ;;
            s)
                _forceFixSockets=true
                ;;
            b)
                _forceFixAws=true
                _forceFixSockets=true
                ;;
        esac
    done

    shift $(( OPTIND - 1 ))

    if [[ -n "$_forceFixAws" ]] || ! aws sts get-caller-identity > /dev/null 2>&1; then
        fix-aws
    fi

    if [[ -n "$_forceFixSockets" ]] || ! ( ${_nextdoorRoot}/scripts/check_unix_bridge.sh ) &>/dev/null; then
        fix-sockets
    fi
}


dbReinstall() (
    # fix-aws checks `git config user.name` to get who you are, so we must not be in a personal repo
    cd "$_nextdoorRoot"

    fixcreds -b
    nd dev resetdb

    fixcreds
    nd dev createdb

    fixcreds
    nd dev django-command re_populate_feed_from_db

    fixcreds
    nd dev taskworker
)


fe-start() {
    declare devProxyIsRunning="`dockerIsContainerRunning 'dev-local-proxy'`"

    if [[ $devProxyIsRunning != 'true' ]]; then
        nd dev portal
    fi

    # Allow only starting the Docker containers without running the build
    if [[ -n "$@" ]]; then
        declare yarnBuildArgs="$@"

        if (( "$#" == 1 )) && [[ "$1" == '.' ]]; then
            yarnBuildArgs=
        fi

        (
            fe
            yarn build --watch "$yarnBuildArgs"
        )
    fi
}
fe-stop() {
    # Unique substrings for front-end Docker containers currently used to proxy API
    # calls and .html rendering for webpack output.
    # Names might change over time to add IDs at the start/end of the actual name,
    # so use these string identifiers to find the actual name to pass to `docker stop`.
    declare feProxyDockerContainers=(
        dev-local-proxy
        dev-portal
        static_1
    )

    for feProxyDockerContainer in "${feProxyDockerContainers[@]}"; do
        declare actualContainerName="$(dockerFindContainer --format '{{.Names}}' "$feProxyDockerContainer")"

        docker stop "$actualContainerName"
    done
}

# Required to give Docker more time to build Nextdoor's bloated containers
export COMPOSE_HTTP_TIMEOUT=1000

be-start() {
    fixcreds

    if ! curl https://static.localhost.com/ 2>/dev/null; then
        STATIC_CONTENT_HOST=https://static.localhost.com:443 NEXTDOOR_PORT=443 nd dev runserver

        if ! curl https://static.localhost.com/ 2>/dev/null; then
            echo 'Error running `nd dev runserver`' >&2
            return 1
        fi
    fi

    echo 'Back-end is running!'
}
be-stop() {
    # Stop all containers. If wanting to run FE, then you'll have to restart them
    stopAllNextdoorDockerContainers
}
