_nextdoorRoot="${NEXTDOOR_ROOT:-$HOME/src/nextdoor.com}"
_nextdoorAwsHost="364942603424.dkr.ecr.us-west-2.amazonaws.com"

export NO_COMMIT_AS=true



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

ndRunDockerImageDx() {
    declare _dxImageTag="${1:-latest}"

    docker run -it --rm "${_nextdoorAwsHost}/dev/dx:$_dxImageTag" /bin/bash
}

ndRunDockerImageWebsiteNextdoor() {
    declare USAGE="[OPTIONS...]
    Runs the nextdoor.com Docker image from AWS.
    Default is the test/staging image; production image can be run by providing an image tag.
    "
    declare _runImageAsServer
    declare _runImageProdTag
    declare -A _ndTestImageOptions=(
        ['s|server,_runImageAsServer']='Run the image as a local server instead of using Bash as an entrypoint.'
        ['p|prod-image-tag:,_runImageProdTag']='Runs the specified production Docker image tag.'
        ['USAGE']="$USAGE"
    )

    parseArgs _ndTestImageOptions "$@"
    (( $? )) && return 1

    declare _mergeBaseCommitHash="$(gitGetMergeBaseForCurrentBranch)"
    declare _ndTestImage="${_nextdoorAwsHost}/dev/nextdoor-test:commit-$_mergeBaseCommitHash"
    declare _ndProdImage="${_nextdoorAwsHost}/nextdoor/nextdoor-com:${_runImageProdTag}"
    declare _ndSelectedImage="$([[ -n "$_runImageProdTag" ]] && echo "$_ndProdImage" || echo "$_ndTestImage")"

    declare _ndTestDefaultExposedPort='8000'

    # DOCKER_NETWORK_IP == 'docker.for.mac.host.internal' on dev computers, but we need actual IP address
    declare _localIpForDockerHost="$(getip -l)"

    declare _runImageExtraOptions=
    declare _runImageCmd=

    if [[ -z "$_runImageAsServer" ]]; then
        _runImageExtraOptions='-it'
        _runImageCmd='/bin/bash'

        if [[ -n "$_runImageProdTag" ]]; then
            _runImageExtraOptions="$_runImageExtraOptions --entrypoint=bash"
            _runImageCmd=
        fi
    else
        _runImageExtraOptions="-p $_ndTestDefaultExposedPort:$_ndTestDefaultExposedPort --add-host localhost.com:$_localIpForDockerHost --add-host localhost:$_localIpForDockerHost"
    fi

    # Not needed currently, but in case we want to add local dev credentials to the docker container:
    # awsCredentialsFile="$HOME/.aws/credentials"
    # AWS_ACCESS_KEY_ID="$(cat "$awsCredentialsFile" | grep -i 'aws_access_key_id' | cut -d '=' -f 2 | sed -E 's/ //g')"
    # AWS_SECRET_ACCESS_KEY="$(cat "$awsCredentialsFile" | grep -i 'aws_secret_access_key' | cut -d '=' -f 2 | sed -E 's/ //g')"
    docker run --rm \
        --mount type=bind,src=${_nextdoorRoot}/static,target=/app/static \
        -e READ_MANIFEST=1 \
        -e RINGBEARER_READ_TIMEOUT=30 \
        -e NEXTDOOR_RINGBEARER_SERVICE_HOST=localhost.com \
        -e SERVICE_FLAVOR=dev_standalone \
        -e AWS_REGION=us-east-1 \
        -e AWS_ACCESS_KEY_ID="${AWS_ACCESS_KEY_ID}" \
        -e AWS_SECRET_ACCESS_KEY="${AWS_SECRET_ACCESS_KEY}" \
        ${_runImageExtraOptions} \
        "$_ndSelectedImage" ${_runImageCmd}
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
