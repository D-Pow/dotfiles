#!/usr/bin/env bash

getArtifactoryToken() {
    declare username="$1"
    declare password="$2"
    declare buildToolType="$3"  # maven, npm, etc.

    declare authJson="$(
        curl -sS \
            -XPOST "https://token-generator.artifactory.homedepot.com/api/${buildToolType}/generateToken" \
            -d username="$username" \
            -d password="$password"
    )"

    if [[ "$authJson" != '{'* ]]; then
        declare error="Error retrieving auth token:\n$authJson"

        if [[ -z "$authJson" ]]; then
            error+="Are you connected to the VPN?"
        fi

        echo -e "$error" >&2

        return 1
    fi

    # Add username to token
    authJson="$(echo "$authJson" | jq ". += {\"user\":\"$username\"} | . += {\"buildToolType\":\"$buildToolType\"}")"
    # Indent entries with 4 spaces and remove color
    declare authJsonPretty="$(echo "$authJson" | jq --indent 4 --monochrome-output '.')"

    echo "$authJsonPretty"
}

outputArtifactoryJson() {
    declare buildToolType="$1"
    declare outputJson="$2"

    if [[ -z "$outputJson" ]]; then
        return 1
    fi

    declare outputFilePath=

    IFS= read -p "Output file for $buildToolType token JSON (STDOUT): " outputFilePath

    if [[ -z "$outputFilePath" ]]; then
        echo "$outputJson"
    else
        echo "$outputJson" > "$outputFilePath"
    fi
}



main() {
    declare buildToolTypes=("$@")

    if (( ${#buildToolTypes[@]} == 0 )); then
        buildToolTypes+=("maven")
    fi

    declare username=
    declare usernameDefault="$(whoami | sed -E 's/./\U&/g')"
    declare password=

    if [[ -z "$username" ]]; then
        # For explanation of `IFS= read ...`, see: https://unix.stackexchange.com/questions/209123/understanding-ifs-read-r-line
        IFS= read -p "Username ($usernameDefault): " username
    fi

    if [[ -z "$password" ]]; then
        # Alternative to hidden input reading - Disabling `echo`:
        #   stty -echo
        #   printf "Password: "
        #   read password
        #   stty echo
        IFS= read -s -p "Password: " password
        printf "\n"
    fi

    username="${username:-$usernameDefault}"

    if [[ -z "$username" ]] || [[ -z "$password" ]]; then
        echo "Error: Please specify username and password." >&2
        return 1
    fi

    declare buildToolType=
    for buildToolType in "${buildToolTypes[@]}"; do
        declare outputJson="$(getArtifactoryToken "$username" "$password" "$buildToolType")"
        (( $? )) && return 1

        outputArtifactoryJson "$buildToolType" "$outputJson"
        (( $? )) && return 1
    done

    return 0
}


# File was called directly, not sourced by another script
if [[ "${BASH_SOURCE[0]}" == "${BASH_SOURCE[ ${#BASH_SOURCE[@]} - 1 ]}" ]]; then
    main "$@"
fi
