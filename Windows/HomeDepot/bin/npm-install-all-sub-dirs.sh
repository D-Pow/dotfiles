#!/usr/bin/env bash

# Jobs = Executions that are sent to the background, including running and paused processes.
# `job` control isn't enabled by default.
# This allows `(fg|bg) $jobId`, etc. job-related commands to work.`
# See: https://stackoverflow.com/questions/11821378/what-does-bashno-job-control-in-this-shell-mean/46829294#46829294
set -m

npmInstallInDir() {
    declare dir="${1:-.}"

    declare parallelProcessPIDs=()
    declare bgCmdPid=
    declare bgExitCodesTotal=0

    echo "Searching $dir for package.json files..."

    declare packageJson=
    for packageJson in $(find "$dir" \( -name 'node_modules' \) -prune -false -o -iname 'package.json'); do
        declare npmDir="$(dirname "$packageJson")/"

        (
            echo "Running \`npm install\` in $npmDir"
            cd "$npmDir"
            npm i
        ) &

        bgCmdPid="$!"

        parallelProcessPIDs+=("$bgCmdPid")
    done

    for bgCmdPid in "${parallelProcessPIDs[@]}"; do
        wait "$bgCmdPid"

        declare bgExitCode="$?"

        (( bgExitCodesTotal += bgExitCode ))
    done

    return $bgExitCodesTotal
}

npmInstallInDirs() {
    declare dirs=("$@")

    if (( ${#dirs[@]} == 0 )); then
        dirs+=('.')
    fi

    declare dir=
    for dir in "${dirs[@]}"; do
        npmInstallInDir "$dir"
    done
}


main() {
    npmInstallInDir "$@"
}

# File was called directly, not sourced by another script
if [[ "${BASH_SOURCE[0]}" == "${BASH_SOURCE[ ${#BASH_SOURCE[@]} - 1 ]}" ]]; then
    main "$@"
fi
