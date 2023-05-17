################
##  Programs  ##
################

resetJetbrains() {
    if isMac; then
        declare _jetbrainsDomains=($(defaults domains | egrep -io "\b[^ ]*com.jetbrains[^ ,]*\b"))

        declare _domain
        for _domain in "${_jetbrainsDomains[@]}"; do
            echo "Deleting domain ${_domain} using \`defaults\`..."

            defaults delete "$_domain"
        done

        # Remove .plist files *after* deleting them from `defaults` so the command can find them initially
        echo "Deleting JetBrains \`.plist\` files from '$HOME/Library/Preferences/'..."
        rm -rf \
            $HOME/Library/Preferences/jetbrains.*.plist \
            $HOME/Library/Preferences/com.jetbrains.*.plist

        # Delete JetBrains' evaluation-info dirs and trial-date files (legacy = options.xml)
        # Century '2xxx' or version 'xxxx.y'
        echo "Deleting trial evaluation files from '$HOME/Library/Application Support/JetBrains/'..."
        rm -rf \
            $HOME/Library/Application\ Support/JetBrains/*[0-9.]*/eval \
            $HOME/Library/Application\ Support/JetBrains/*[0-9.]*/options/other.xml \
            $HOME/Library/Application\ Support/JetBrains/*[0-9.]*/options/options.xml
    elif isLinux; then
        echo "Deleting trial evaluation files from '$HOME/.config/JetBrains/'..."
        rm -rf \
            $HOME/.config/JetBrains/*/options/other.xml \
            $HOME/.config/JetBrains/*/options/eval* \
            $HOME/.config/JetBrains/*/eval*
    fi
}



################
###  NodeJS  ###
################

npms() {
    # regex is homemade linux/bin/regex python script
    regex '"scripts": [^\}]*\}' ./package.json
}

# By default, allow ES modules, importing JSON, top-level await, and other relevant/useful features
# See:
#   https://github.com/D-Pow/react-app-boilerplate/blob/master/.npmrc
#   https://nodejs.org/api/cli.html#cli_node_options_options
NODE_OPTIONS='--experimental-modules --experimental-json-modules --experimental-top-level-await --experimental-import-meta-resolve'

npmValidatePackageLockResolvedUrls() {
    declare _nonNpmRegistryPackages="$(cat package-lock.json \
        | egrep -i '^\s*"resolved":' \
        | grep -v 'resolved": "https://registry.npmjs.org'
    )"

    if [[ -n "$_nonNpmRegistryPackages" ]]; then
        echo "$_nonNpmRegistryPackages" >&2
        return 1
    fi
}

alias npmrtf="npm run test 2>&1 | egrep -o '^FAIL.*'" # only print filenames of suites that failed
# npm@>=8 prints the dependencies in a white space-indented nested list with "Depends on"
# npm@<=7 prints them in a non-ASCII table with "Dependency of"
# Nested dependencies of both will either not match those strings or will start with >= 3 spaces
alias npmPackagesWithVulns="npm audit | egrep '(Dependency of)|(^..Depends on)' | egrep -v '^\s{3,}' | sort -u | egrep -o '\S+(?=(\s\[\w+\])|$)' | awk '/[:ascii:]/ { print }' | sort -ur"

npmGetProjectPath() {
    npm prefix
}

npmConfigGetFile() {
    declare USAGE="${FUNCNAME[0]} [-u|-g] [-l|-a]
    Gets either:
    1. The path to the config file (Location: -u=User, -g=Global, default=project).
    2. The config keys/values specified from all configs (-l=List), optionally including unspecified/default values (-a=All).
    "
    declare configLocationDefault='project'
    declare configLocation="$configLocationDefault"
    declare configList=
    declare configListAll=
    declare OPTIND=1
    declare opt

    while getopts ':ugla' opt; do
        case "$opt" in
            u)
                configLocation='user'
                ;;
            g)
                configLocation='global'
                ;;
            l)
                configList=true
                ;;
            a)
                configList=true
                configListAll='-l'
                ;;
            *)
                echo -e "$USAGE" >&2
                return 1;
        esac
    done

    shift $(( OPTIND - 1 ))

    if [[ -n "$configList" ]]; then
        # Note: `--location` flag technically not needed when listing, but added for completeness
        # to show how to use with `npm config (get|set)`
        npm config --location "$configLocation" $configListAll list
    elif [[ "$configLocation" != "$configLocationDefault" ]]; then
        # `userconfig` and `globalconfig` are npm built-ins but `projectconfig` isn't
        npm config get "${configLocation}config"
    else
        echo "$(npmGetProjectPath)/.npmrc"
    fi
}

npmConfigScopedPackageFormatUrl() {
    # Strip out the protocol (usually `https:`) from the given URL to match the format
    # required for specific packages' auth tokens and related configs.
    # Result will be akin to:
    #   //url.com/my-pkg:configKey=configVal
    echo "$1" | sed -E 's|^.*?:(//)|\1|'
}

npmConfigIsRegistryAccessible() {
    declare registryName="${1:+$1:}"

    npm ping --registry $(npm config get "${registryName}registry") &>/dev/null
}

npmr() {
    npm run "$@"
}
_autocompleteNpmr() {
    declare lastCommandWordIndex=$COMP_CWORD
    declare commandWords="${COMP_WORDS[@]}"
    declare currentWord="${COMP_WORDS[COMP_CWORD]}"

    # Don't show suggestions if the first arg has already been autocompleted.
    if (( $lastCommandWordIndex > 1 )); then
        return
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
    declare availableCommands="$(npm run | egrep -o '^  \S*' | egrep -v '^\s*$' | sed -E 's|\s||g')"
    declare commandsMatchingUserInput="$(echo "$availableCommands" | egrep "^$currentWord")"

    COMPREPLY=($(compgen -W "$commandsMatchingUserInput"))

    return
}
complete -F _autocompleteNpmr -o default "npmr" # default shell autocomplete for dirs/files via `-o default`.
complete -F _autocompleteNpmr -o default "yarn"


export NVM_DIR="$([[ -n "$XDG_CONFIG_HOME" ]] && echo "$XDG_CONFIG_HOME/nvm" || echo "$HOME/.nvm")"
[ -s "$NVM_DIR/nvm.sh" ] && source "$NVM_DIR/nvm.sh"  # Load nvm
[ -s "$NVM_DIR/bash_completion" ] && source "$NVM_DIR/bash_completion"  # Load nvm bash_completion
export NVM_SYMLINK_CURRENT=true # Makes a symlink at ~/.nvm/current/bin/node so you don't have to change IDEs' configurations when changing node versions
export NVM_CURRENT_HOME="$NVM_DIR/current"
export PATH="$NVM_CURRENT_HOME/bin:$PATH"

# Make NODE_PATH always include the `node_modules/` directory of the currently selected NodeJS.
# While not advised (see refs), this is helpful for e.g. individual NodeJS scripts placed in
# a `bin/` directory of this repo.
#
# Refs:
#   NODE_PATH and ways to set it: https://stackoverflow.com/questions/7970793/how-do-i-import-global-modules-in-node-i-get-error-cannot-find-module-module
#   NODE_PATH isn't meant to include globals: https://github.com/nvm-sh/nvm/issues/1290#issuecomment-261320632
#
# Here, we get the global `node_modules/` manually from NVM's `current/` dir so it always uses the
# active Node version. If we used `npm root -g` instead, we'd be locked into the version active when
# the `.profile` is sourced.
#
# `-L` = Keep symlinks in output as well as allow searching within them.
# Remove "symlink is a cycle" errors.
# `sed` = Remove nested global node_modules dirs from the top-level node_modules dir.
# `trim` = Remove superfluous spaces.
_nvmCurrentNodePath="$(
    find -L "$NVM_CURRENT_HOME" -iname node_modules 2>/dev/null \
        | sed -E 's|.*node_modules/.+||' \
        | trim
)"
export NODE_PATH="$(str.unique -d ':' "${NODE_PATH:+${NODE_PATH}:}$_nvmCurrentNodePath")"


yarnRerunCommand() {
    # Re-runs a `yarn` command, killing the original great grandparent parent `yarn` process
    # if needed.
    #
    # Default to reading yarn command/args from function args.
    # e.g. `yarnRerunCommand add pkg-a pkg-b` where `add` is the command and the rest are flags/args.
    declare yarnCommand="$1"
    shift
    declare yarnArgs=("$@")

    if [[ -z "$yarnCommand" ]]; then
        # Fallback to reading them from original command run/npm env var
        yarnCommand="$(getYarnArgs -c)"
        yarnArgs=($(getYarnArgs))
    fi

    declare yarnRerunExitCode=$?

    # Since this is a re-run of a command, the parent `yarn` process is still running, waiting
    # for this Bash script (a deeply nested child process) to finish.
    #
    # For commands related to installing packages (like `yarn`, `yarn install`, `yarn (add|upgrade) <pkg>`),
    # yarn will always assume a change is needed. This means duplicate installs will take place (first from
    # the re-run, second from the original parent).
    # For public packages, this is just bad dev experience with no issues or crashes, but for private
    # packages requiring auth credentials set by the registry-login script, this means the parent yarn
    # process will crash since .npmrc/.yarnrc weren't modified before the command was run (their
    # values have already been loaded into RAM so changes won't be picked up).
    #
    # Thus, when re-running the original command, kill the parent process running the same command so
    # that it doesn't crash when it finds it wasn't authenticated (which has the additional benefit
    # of not duplicating installs or re-calling life-cycle methods).
    #
    # In order to do so, wait until this process (calling the re-run) has ended, and then kill the
    # parent process of this Bash script so that all logic will be run before killing the parent.
    # This keeps the return code of the child and forwards it up to the parent, e.g.
    # - `yarn install` -> `yarn preinstall`
    # - `yarn preinstall` -> `./scripts/registry-login.sh`
    # - `./scripts/registry-login.sh` -> `if not-logged-in; then yarnRerunCommand; fi`
    # - Success/failure of the re-run is forwarded up the call stack.
    #
    # Note: Use SIGINT instead of SIGTERM (default) or otherwise because they often force exit codes > 0
    # even if run from sub-commands/sub-processes, but exit with the same exit code that the re-run command
    # exited with to preserve success/failure.
    #
    # See:
    # - https://serverfault.com/questions/390846/kill-a-process-and-force-it-to-return-0-in-linux
    # - https://linux.die.net/Bash-Beginners-Guide/sect_12_01.html
    declare parentProcessPid=$(findPids "yarn(.js)? $(getYarnArgs -k)")

    trap "yarnRerunExitCode=\$?; [[ -n \"$parentProcessPid\" ]] && kill -s INT $parentProcessPid; exit \$yarnRerunExitCode;" EXIT QUIT INT TERM

    ( yarn $yarnCommand ${yarnArgs[@]} )

    yarnRerunExitCode=$?

    return $yarnRerunExitCode
}



################
###  Python  ###
################


if [[ -z "$VIRTUAL_ENV" ]] && ! echo "$(which python)" | grep -iq conda; then
    # If not in a virtual environment nor Conda environment,
    # then make Python v3 the default for `python` command
    alias python='python3'
    alias python2='/usr/bin/python'
fi


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



#########################
###  GitHub CLI (gh)  ###
#########################
# REST API: https://docs.github.com/en/rest
# CLI: https://cli.github.com/manual
#   Install: https://github.com/cli/cli#installation

ghScopes() {
    # Docs: https://cli.github.com/manual/gh_api
    gh api -i user | grep -i 'X-Oauth-Scopes: ' | sed -E 's/.*: //'
}

ghAuthToken() {
    # Docs: https://cli.github.com/manual/gh_auth_status
    # For some reason, `gh auth` outputs info to STDERR (likely to prevent users from doing what I'm doing here)
    gh auth status --show-token 2>&1 | grep -i 'token' | sed -E 's/.*: //'
}

ghAuthForGitHubPackages() {
    # Required scopes: https://docs.github.com/en/packages/learn-github-packages/about-permissions-for-github-packages#about-scopes-and-permissions-for-package-registries
    # Modifying scopes: https://cli.github.com/manual/gh_auth_refresh
    declare _requiredScopes=('read:packages')
    declare _requiredScopesRegex="$(printf '(%s)|' "${_requiredScopes[@]}" | sed -E 's/.$//')" # strip off trailing `|`
    declare _currentScopes="$(ghScopes | sed -E 's/ //g')"

    if ! ghScopes | egrep -iq "$_requiredScopesRegex"; then
        echo "You don't have the required scopes \"${_requiredScopes[@]}\" to access GitHub Packages. Adding them now..."

        declare _newScopes="$(printf '%s,' "${_requiredScopes[@]}")${_currentScopes}" # keep trailing comma to easily add current scopes at the end

        gh auth refresh --scopes "$_newScopes"
    fi
}

ghLoginToGitHubPackagesNpmRegistry() {
    # Ref: https://docs.github.com/en/packages/working-with-a-github-packages-registry/working-with-the-npm-registry
    declare _npmScope="$1"

    if [[ -z "$_npmScope" ]]; then
        echo "No scope specified! Please specify the scope used for your npm packages." >&2
        return 1
    fi

    ghAuthForGitHubPackages

    # Or: gh api user | jq -r '.login' | str.lower
    declare _npmLoginUsername="$(git config --global user.name)"
    declare _npmLoginPasswordToken="$(ghAuthToken)"
    declare _npmLoginEmail="$(git config --global user.email)"

    declare _npmGitHubRegistryUrl='https://npm.pkg.github.com'
    declare _npmConfigGitHubKeyPrefix="$(npmConfigScopedPackageFormatUrl "$_npmGitHubRegistryUrl")/:"
    declare _npmConfigGitHubTokenField="${_npmConfigGitHubKeyPrefix}_authToken"

    echo "Logging into npm registry \"$_npmGitHubRegistryUrl\" with username \"$_npmLoginUsername\" and email \"$_npmLoginEmail\"..."

    # Note: We can't just do
    #   echo -e "$field1\n$field2\n$field3\n..." | npm login ...
    # nor
    #   npm login ... < <(echo -e "...")
    # because `npm login` shows prompts so each field must be injected sequentially, waiting for the
    # next prompt to appear before we `echo` it.
    # Thus, add a `sleep` call to ensure we wait long enough for the next prompt to appear.
    # See:
    #   https://stackoverflow.com/questions/23460980/how-to-set-npm-credentials-using-npm-login-without-reading-from-stdin
    npm login --scope="$_npmScope" --registry="$_npmGitHubRegistryUrl" < <(
        declare _npmLoginField
        for _npmLoginField in {"$_npmLoginUsername","$_npmLoginPasswordToken","$_npmLoginEmail"}; do
            echo "$_npmLoginField"
            sleep 1
        done
    )

    # Usually, npm config fields prefixed with an underscore are protected and will throw an error
    # if a read is attempted.
    # Thus, fallback to just listing the config fields and ensuring the field exists manually.
    if
        [[ "$(npm config --global get "$_npmConfigGitHubTokenField" 2>/dev/null)" == "$_npmLoginPasswordToken" ]] \
        || \
        npmConfigGetFile -l | egrep -iq "$_npmConfigGitHubTokenField" \
    ; then
        echo 'Logged in successfully!'
    else
        echo 'Error: Could not login to GitHub npm registry.' >&2
    fi
}

ghPrShow() {
    # Shows PRs and their info, whether created by you or requesting your review.
    #
    # TODO - Add more commands/options like `closed` PRs, `closed reviewed-by:@D-Pow`, etc.
    #
    # See:
    #   GitHub issue about `gh` formatting: https://github.com/cli/cli/issues/846#issuecomment-1142104190
    #   `gh pr list` docs: https://cli.github.com/manual/gh_pr_list
    #   `gh pr status` docs: https://cli.github.com/manual/gh_pr_status
    #   `gh` API: https://cli.github.com/manual/gh_api
    #   `awk` docs: https://www.gnu.org/software/gawk/manual/gawk.html#String-Functions
    #   SO post - how to split lines from vars in awk: https://stackoverflow.com/questions/41591828/use-bash-variable-as-array-in-awk-and-filter-input-file-by-comparing-with-array/41591888#41591888
    #   SO post - how to handle arrays/matrices in awk: https://stackoverflow.com/questions/50658752/use-awk-to-match-store-append-the-pattern-and-also-split-the-line-having-a-de
    #   SO post - creating matrices from strings in awk: https://stackoverflow.com/questions/19606816/bash-awk-split-string-into-array
    #   SO post - how to check if key exists in matrix: https://stackoverflow.com/questions/26746361/check-if-an-awk-array-contains-a-value/41604944#41604944
    #   Forum question about awk matrices: https://www.unix.com/shell-programming-and-scripting/157424-two-column-data-matrix-awk.html
    #   Printing matrices in awk (since they can't be done natively): https://www.unix.com/shell-programming-and-scripting/203159-need-have-output-awk-array-one-line.html
    declare _prStatuses="$(gh pr status | egrep -i 'created|requesting|#')" #  | esed 's/^[ \t]*//'
    declare _prNumbers=$(echo "$_prStatuses" | egrep -o '^[ \t]*#\d+' | egrep -o '\d+' | tr -s '\n' ' ')
    declare _prInfo="$(gh pr list \
        --json number,title,headRefName,author \
        --template '{{range .}}{{tablerow (printf "#%v" .number | autocolor "green") .title (.headRefName | color "cyan") (.author.login | color "yellow") }}{{end}}' \
        --search "$_prNumbers"
    )"

    echo "$_prStatuses" | awk -v prInfo="$_prInfo" '
        BEGIN {
            # Splits PR info lines from `gh pr list` into separate array entries
            split(prInfo, prInfoArrayFlat, "\n")

            for (line in prInfoArrayFlat) {
                # Get the text itself
                prInfoLine=prInfoArrayFlat[line]

                # Strip leading/trailing spaces in-place
                gsub(/(^[ \t]+)|([ \t]+$)/, "", prInfoLine)

                # Split the line itself into an array to get the first entry (the PR number)
                split(prInfoLine, prInfoLineArray)

                prNumber=prInfoLineArray[1]

                # Set the PR number as a key in an associative array: { prNumber: prInfoLine }
                # This is easier than iterating through a standard array and/or using `NR`
                prInfoArray[prNumber]=prInfoLine
            }
        }
        {
            if ($1 in prInfoArray) {
                # Print the PR info from the more descriptive text than the `gh pr status` text
                print prInfoArray[$1]
            } else if ($1 ~ /^\w/) {
                # Print the `Created by you`/`Requesting review` lines themselves
                printf("\n%s\n", $0)
            }
        }
    '
}

_ghRunParseOpts() {
    declare -n parentUsage="USAGE"
    declare _USAGE="

    [OPTIONS...]
    Executes \`gh run <cmd>\`, casting partial options to correct ones.

    e.g. \`--repo\` will inject owner/repoName if both are not specified by the parent.
        (correct format of \`gh run --repo <str>\` is \`[HOST/]owner/repository\`)
    "
    declare _repoName=
    declare _repoOwner=
    declare -A _ghRunOpts=(
        ['r|repo:,_repoName']="Repository name (default: \$(gitGetRepoName))."
        ['o|owner:,_repoOwner']="Owner of the repository (default: \`git config user.name\`)."
        ['USAGE']="${parentUsage}${_USAGE}"
        [':']=
    )
    declare argsArray=

    parseArgs _ghRunOpts "$@"
    (( $? )) && return 1

    declare ghCmdOpts=()

    if [[ -n "$_repoName" ]] || [[ -n "$_repoOwner" ]]; then
        _repoName="${_repoName:-$(gitGetRepoName)}"
        _repoOwner="${_repoOwner:-$(git config user.name)}"

        ghCmdOpts+=("--repo" "${_repoOwner}/${_repoName}")
    fi

    gh run ${ghCmdOpts[@]} ${argsArray[@]}
}

ghPipelineLs() {
    declare USAGE="[OPTIONS...]
    Lists the status of all GitHub pipelines.
    "

    _ghRunParseOpts "$@" list
}

ghPipelineWatch() {
    declare USAGE="[OPTIONS...]
    Watches the progress of a single GitHub pipeline.
    "

    _ghRunParseOpts "$@" watch
}

ghActionsValidate() {
    # See: https://github.com/rhysd/actionlint/blob/main/docs/usage.md#docker
    declare _ghActionsValidateRepoDir="${1:-$(pwd)}"

    docker run --rm -v ${_ghActionsValidateRepoDir}:/repo --workdir /repo rhysd/actionlint:latest -color
}



################
###  Docker  ###
################
# https://docs.docker.com/engine/reference/commandline/docker/

dockerFindContainer() {
    # Enhanced `docker ps` that filters by any field instead of only by name, ID, image, etc.
    # and allows regex queries.
    # Docs: https://docs.docker.com/engine/reference/commandline/ps
    declare -A _dockerFindContainerOpts=(
        [':']=
        ['?']=
    )
    declare argsArray

    parseArgs _dockerFindContainerOpts "$@"
    (( $? )) && return 1

    declare _dockerPsOpts
    declare _dockerPsQueryArray

    # All args before the last one
    array.slice -r _dockerPsOpts argsArray 0 -1
    # Last arg is image name query string
    array.slice -r _dockerPsQueryArray argsArray -1

    declare _dockerPsQuery="${_dockerPsQueryArray[0]}"

    # First, get matching results based on any search query (container ID, image, container name, etc.).
    # Then, apply the user's search criteria to the matches afterwards.
    # This is required first because:
    #   Calling `grep` after the user's `ps` options might result in 0 results (e.g. `docker ps -q` removes filtering based on image).
    #   Calling `grep` before `ps` options means we have to parse out the options manually (e.g. `docker ps -q` means we'd have to use `cut` to get only the first column).
    # Also, calling `docker ps` a second time with the user's `ps` options means we can let docker
    # handle the header output itself, too.
    # To call it a second time, remove the headers from this initial filter call so it doesn't
    # interfere with the second call.
    declare _dockerPsMatches="$(docker ps -a | egrep -iv 'CONTAINER\s*ID\s*IMAGE' | egrep -i "$_dockerPsQuery")"

    if [[ -z "$_dockerPsMatches" ]]; then
        return 1
    fi

    # Get only the container IDs so we can add our own custom `--filter` query to the `ps` options.
    # Works with any other option, including other `--filter` entries, `-q`, etc.
    declare _dockerPsMatchesContainerIds=($(echo "$_dockerPsMatches" | cut -d ' ' -f 1))
    declare _containerId

    for _containerId in "${_dockerPsMatchesContainerIds[@]}"; do
        _dockerPsOpts+=('--filter' "id=$_containerId")
    done

    docker ps -a "${_dockerPsOpts[@]}"
}

dockerIsContainerRunning() {
    declare imageId="`dockerFindContainer -q "$1"`"

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

dockerDeleteContainer() {
    docker rm --volumes $(dockerFindContainer -q "$@")
}

dockerPurgeAllStoppedContainersImagesAndNetworks() {
    docker system prune -a --volumes
}

dockerGetVolumesForContainers() (
    declare IFS=$'\n'
    declare allDockerDriversAndVolumes=($(docker volume ls | grep -vi driver))
    declare dockerDriversVolumesAndContainers=()

    for dockerVolume in ${allDockerDriversAndVolumes[@]}; do
        declare volumeDriver="$(echo "$dockerVolume" | awk '{ print $1 }')"
        declare volumeId="$(echo "$dockerVolume" | awk '{ print $2 }')"
        declare matchingContainerName="$(dockerFindContainer --filter "volume=$volumeId" --format '{{.Names}}' "${@:-.}")"

        if (( $# == 0 )); then
            dockerDriversVolumesAndContainers+=("${matchingContainerName:-<null>}\t$volumeId\t$volumeDriver\n")
        elif [[ -n "$matchingContainerName" ]]; then
            dockerDriversVolumesAndContainers+=("${matchingContainerName:-<null>}\t$volumeId\t$volumeDriver\n")
        fi
    done

    if ! array.empty dockerDriversVolumesAndContainers; then
        # Append headers to the beginning of the output
        dockerDriversVolumesAndContainers=("CONTAINER\tVOLUME\tDRIVER\n" ${dockerDriversVolumesAndContainers[@]})
        # Align output results in tab-separated columns
        echo -e "${dockerDriversVolumesAndContainers[@]}" | column -t -c 3 -s $'\t'
    fi
)

dockerShowDockerfileForImage() (
    declare _imageId="$(docker image ls -q "$1")"
    docker run --rm -i -v /var/run/docker.sock:/var/run/docker.sock chenzj/dfimage "$_imageId"
)

dockerContainerInfo() {
    # Inspired by: https://stackoverflow.com/questions/38946683/how-to-test-dockerignore-file
    declare _dockerfilePath="${1:-"$(pwd)"}"

    declare _utilImageName='docker-show-context'
    declare _utilImageRepo='https://github.com/pwaller/docker-show-context.git'
    declare _utilImageExists="$(docker image ls -q "$_utilImageName")"

    if [[ -z "$_utilImageExists" ]]; then
        # Pull/build image only if it hasn't been pulled before
        #
        # Note that building separately from running the Docker image is necessary for
        # Git repos when they don't deploy the image itself somewhere
        #
        # See:
        #   - https://stackoverflow.com/questions/26753030/how-to-build-docker-image-from-github-repository/39194765#39194765
        docker build -t "$_utilImageName" "$_utilImageRepo"
    fi

    docker run --rm -v "$_dockerfilePath":/data docker-show-context
}

dockerShowRunCommandForContainers() (
    (( $# )) || { echo "Please specify container ID(s)/name(s)" >&2; return 1; }

    declare IFS=$'\n'
    # The output has additional newlines injected so remove duplicates with `tr` and the first one with `tail`
    declare _allRunCommands=($(
        docker run --rm -i -v /var/run/docker.sock:/var/run/docker.sock nexdrew/rekcod "$@" \
            | tr -s '\n' \
            | tail -n +2
    ))

    # Associate each run command with each requested container name/ID
    for (( i = 0; i < $#; i++ )); do
        declare _containerForRunCmd="${@:(( $i + 1 )):1}"
        declare _runCmdForContainer="${_allRunCommands[i]}"

        echo "\"$_containerForRunCmd\""
        echo "$_runCmdForContainer"

        (( $i < ($# - 1) )) && echo -e '\n-----\n'
    done
)

dockerGetLogs() {
    declare _dockerLogOutputFile
    declare _dockerContainerName
    declare OPTIND=1

    while getopts "o:n:" opt; do
        case "$opt" in
            o)
                _dockerLogOutputFile="$OPTARG"
                ;;
            n)
                _dockerContainerName="$OPTARG"
                ;;
            *)
                declare _passedArg="${!OPTIND}"

                if [[ "$_passedArg" =~ --[a-zA-Z0-9] ]]; then  # String comparison regex (simple bash regex) cannot be quoted
                    declare _errMsg=

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



################
###  AWS CLI  ##
################
# Configuration: https://docs.aws.amazon.com/cli/latest/userguide/cli-chap-configure.html
# Env vars: https://docs.aws.amazon.com/cli/latest/userguide/cli-configure-envvars.html
# Docker image: https://docs.aws.amazon.com/cli/latest/userguide/install-cliv2-docker.html
# Example purpose - CodeArtifact as an npm registry: https://docs.aws.amazon.com/codeartifact/latest/ug/npm-auth.html#configuring-npm-without-using-the-login-command

awsCmd() {
    # Attempt to use natively-installed `aws` command, but fallback to Docker image with all
    # local env vars set
    declare cmd

    if isDefined aws; then
        cmd='aws'
    else
        cmd='awsCmdInDocker'
    fi

    $cmd "$@"
}

awsDescribeKey() {
    awsCmd kms describe-key --key-id "$1" | jq --indent 4 '.KeyMetadata'
}

awsKeyPolicyNames() {
    awsCmd kms list-key-policies --key-id "$1" | jq '.PolicyNames'
}

awsKeyPolicy() {
    # Comes in the annoying form of an escaped JSON key
    # e.g. `{ Policy: "{\n    \"Key1\": \"Val1\",\n ... }" }`
    # So reformat it to a usable form:
    #   Convert `\n` to newlines with `echo -e`
    #   Remove superfluous escapes `\"` and `("{)|(}")`
    # Note: `sed` doesn't have non-capture groups, but does count capture groups in the order:
    #   1. outside-to-inside
    #   2. left-to-right
    # So we can write a makeshift non-capture group by capturing all first (necessary for the `|` operator)
    # and then specifying another inner capture group which we keep in the substitution.
    echo -e "$(
        awsCmd kms get-key-policy --key-id "$1" --policy-name "${2:-default}"
    )" \
        | sed -E 's/\\"/"/g; s/("(\{))|((\})")/\2\4/g' \
        | jq --indent 4 '.'
}

awsGetAllKeysInfo() {
    # Not the same as "Access key"
    declare allKeyIds=($(aws kms list-keys | jq -r '.Keys[] | .KeyId'))
    declare allKeyInfo='[]'

    declare keyId
    for keyId in "${allKeyIds[@]}"; do
        declare keyMetadata="$(awsDescribeKey "$keyId")"
        declare keyPolicy="$(awsKeyPolicy "$keyId")"
        declare keyInfo="$(echo "[ $keyMetadata , $keyPolicy ]" | jq '.[0] + .[1]')"

        allKeyInfo="$(echo "$allKeyInfo" | jq ". + [ $keyInfo ]")"
    done

    echo "$allKeyInfo" | jq --indent 4 '.'
}

awsCmdInDocker() {
    declare USAGE="${FUNCNAME[0]} [-e envVar=envVal] [-b] <aws-command>
    Runs an AWS CLI command either:
        * Locally if installed.
        * In an ephemeral Docker container if not installed.

    Passes all \`AWS_{VAR}\` environment variables to the container, but they can be overridden via \`-e AWS_VAR=value\`.

    Options:
        -e var=val  |   Equivalent of Docker's \`-e\` flag; forwarded directly to the container.
        -b          |   Run \`bash\` instead of \`aws\`.
    "

    declare cmdToRun='aws'
    declare envVars=()
    declare envVar=

    # Prefill `envVars` with environment variables from the system.
    # This is okay because `docker run -e a=A -e a=B ...` will overwrite duplicate vars with the
    # last one seen.
    for envVar in $(compgen -v AWS_); do
        envVars+=("$envVar=${!envVar}")
    done

    # Now, add user-specified env vars that will override system env vars
    declare OPTIND=1
    declare opt
    while getopts ':e:b' opt; do
        case "$opt" in
            e)
                envVars+=("$OPTARG")
                ;;
            b)
                cmdToRun='bash'
                ;;
            *)
                echo -e "$USAGE" >&2
                return 1
                ;;
        esac
    done

    shift $(( OPTIND - 1 ))

    # Populates the `.aws/credentials` file with all `AWS_X` vars from the environment/user
    declare autoGenerateAwsDirAndCredentialsCommand='
        mkdir /root/.aws;
        echo "[$AWS_PROFILE]" > /root/.aws/credentials;
        (
            unset AWS_PROFILE;
            for envVar in $(compgen -v AWS); do
                echo "$envVar ${!envVar}" | awk "{ printf \"%s = %s\n\", tolower(\$1), \$2 }";
            done;
        ) >> /root/.aws/credentials;
        '
    # Run the `aws` command within the Docker container after creating credentials file
    # or `bash` if specified
    declare runCommand="$autoGenerateAwsDirAndCredentialsCommand $cmdToRun $@"

    # Override the `ENTRYPOINT` of Docker image to Bash so we don't have to mount local credentials
    # i.e. `-v $HOME/.aws:/root/.aws`
    docker run -it --rm --entrypoint bash $(
        for envVar in "${envVars[@]}"; do
            echo "-e $envVar"
        done
    ) amazon/aws-cli -c "$runCommand"
}
