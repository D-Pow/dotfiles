#!/usr/bin/env bash

hdVid() {
    declare USAGE="${FUNCNAME[0]} [OPTIONS...]
    Generates a new VID token for use in the scanner.

    Options:
        -v <token>  |   Output if the token is valid (invalidates the token in the process).
        -w          |   Append HD Wallet PIDs Base64 encoded string to VID.
        -h          |   Print this message.
    "

    declare hdWalletAuthorized=
    declare verifyToken=
    declare OPTIND=1
    while getopts ":wv:h" opt; do
        case "$opt" in
            w)
                hdWalletAuthorized=true
                ;;
            v)
                # # Read next arg only if not a flag (prefixed with a hyphen).
                # # Usually, this would be "$OPTARG" if we used `getopts "v:"`
                # # but since we didn't specify that in `getopts`, manually
                # # read next arg.
                # # This allows `{func} -v <token>` and `{func} <token>`.
                # if ! [[ "${!OPTIND}" =~ ^-[a-zA-Z] ]]; then
                #     verifyToken="${!OPTIND}"
                # else
                #     verifyToken='true'
                # fi
                verifyToken="$OPTARG"
                ;;
            h)
                echo -e "$USAGE"
                return 1
                ;;
        esac
    done
    shift $(( OPTIND - 1 ))

    declare -A logins=(
        ['b2btestperksstaguser187@mailinator.com']='Test@1234'
        ['b2btestperksstaguser209@mailinator.com']='Test1234'
        ['b2btestperksstaguser216@mailinator.com']='Test54321'
        ['b2btest50@gmail.com']='testqa01'
    )
    declare usernames=("${!logins[@]}")  # Stable array order, usually alphabetical
    declare defaultLogin="${usernames[2]}"

    declare username="${1:-"$defaultLogin"}"
    declare password="${2:-"${logins["$username"]}"}"

    declare devApiDomain="hd-qa74.homedepotdev.com"
    declare cookieJar="$(pwd)/.cookie-jar.txt"

    trap "rm -f \"$cookieJar\"" EXIT QUIT INT TERM

    declare utcInMillis="$(date +%s000)"
    declare hmacCreationTime="$utcInMillis"
    declare resGetAuthToken="$(
        curl -sSL \
            --cookie-jar "$cookieJar" \
            -H "timestamp: $hmacCreationTime" \
            -H "clientId: clientId" \
            "https://${devApiDomain}/customer/account/v1/auth/getauthtoken"
    )"
    declare clientAuthToken="$(echo "$resGetAuthToken" | jq -r '.clientAuthToken')"

    # curl
    #   -s, --silent
    #       Silent (don't show progress bar).
    #   -S, --show-error
    #       Show errors even if silent.
    #   -f, --fail
    #       Fail silently (don't show errors).
    #   -L, --location
    #       Follow redirects.
    #   -c, --cookie-jar <file>
    #       Store new cookies in cookie jar.
    #   -b, --cookie <file>
    #       Use cookies from cookie jar.
    #
    # Set new cookies from responses via `--cookie-jar`, and then reuse them
    # in subsequent calls via `--cookie`.
    # Use both to read from/write to cookie jar after this request.
    declare resSignIn="$(
        curl -sSL \
            --cookie "$cookieJar" \
            --cookie-jar "$cookieJar" \
            -H "cust-acct-client-token: $clientAuthToken" \
            -H "cust-acct-client-timestamp: $hmacCreationTime" \
            -H "cust-acct-client-id: clientId" \
            -H "cust-acct-client-delay-token-validation: 444444" \
            -H "channelId: 1" \
            -H "Content-Type: application/json" \
            -H "Accept: application/json" \
            -H "User-Agent: neoload" \
            -X POST \
            --data "
                {
                    \"email\": \"$username\",
                    \"password\": \"$password\",
                    \"sessionId\": \"sessionId\"
                }
            " \
            "https://${devApiDomain}/customer/auth/v1/signin"
    )"
    declare email="$(echo "$resSignIn" | jq -r '.email')"
    declare customerType="$(echo "$resSignIn" | jq -r '.customerType')"
    declare userId="$(echo "$resSignIn" | jq -r '.userID')"
    declare svocId="$(echo "$resSignIn" | jq -r '.svocID')"

    declare signinAuthTokenCookieName=
    # Set cookie name based on customer type
    if [[ "$customerType" =~ 'B2C' ]]; then
        signinAuthTokenCookieName='THD_USER_SESSION'
    else
        signinAuthTokenCookieName='THD_CUSTOMER'
    fi
    # Extract cookie from cookie jar based on the name
    declare signinAuthToken="$(grep -Pi "$signinAuthTokenCookieName" "$cookieJar" | awk '{ print $7 }')"

    declare resGenerateVid="$(
        curl -sSL \
            --cookie "$cookieJar" \
            --cookie-jar "$cookieJar" \
            -H "Authorization: $signinAuthToken" \
            -H "TMXProfileId: tmxProfileId" \
            -H "Content-Type: application/json" \
            -H "Accept: application/json" \
            -H "User-Agent: neoload" \
            -X POST \
            --data "
                {
                    \"userId\": \"$userId\",
                    \"svocId\": \"$svocId\"
                }
            " \
            "https://${devApiDomain}/customer/auth/v1/vid"
    )"
    declare vidToken="$(echo "$resGenerateVid" | jq -r '.token')"
    declare vidCreationDate="$(echo "$resGenerateVid" | jq -r '.creationDate')"
    declare vidTtl="$(echo "$resGenerateVid" | jq -r '.ttl')"
    declare vidTokenKey="${vidToken:4:${#vidToken}}"  # Length isn't necessary, but added for clarity

    if [[ -n "$verifyToken" ]]; then
        # Fall back to generated token
        declare vidTokenKeyInput="${verifyToken:-"${1:-"$vidTokenKey"}"}"

        declare resVidValidation="$(
            curl -sSL \
                -H "authority: ${devApiDomain}" \
                -H "channelId: 1" \
                -H "Origin: https://${devApiDomain}" \
                -H "Referer: https://${devApiDomain}/auth/view/signin" \
                -H "x-quantumsessionid: 63e50a50e43f9a2c00772bea40eb2062" \
                -H "x-quantumuserid: 4a0334664fb0a0b93dcb9dcc85966746" \
                -H "x-trace-uuid: a2f784db-d643-4418-ba3c-04957500417e" \
                -H "Content-Type: application/json" \
                -H "Accept: application/json" \
                -H "User-Agent: neoload" \
                -X POST \
                --data "
                    {
                        \"vidJWT\": \"$vidTokenKeyInput\"
                    }
                " \
                "https://${devApiDomain}/customer/auth/v1/vid/validate"
        )"
        declare vidTokenStatus="$(echo "$resVidValidation" | jq -r '.status')"
        declare vidTokenUserId="$(echo "$resVidValidation" | jq -r '.userId')"
        declare vidTokenSvocId="$(echo "$resVidValidation" | jq -r '.svocId')"

        echo "$vidTokenStatus"
    fi

    declare hdWalletPids='{"p_ids":["P124F797A43BF07A80","P124B5F06900370620","P124DDDB8D29541E40"]}'
    declare hdWalletPidsBase64="$(echo "$hdWalletPids" | base64 | sed -E 's/K$/=/')"

    if [[ -n "$hdWalletAuthorized" ]]; then
        echo "$vidToken,$hdWalletPidsBase64"
    else
        echo "$vidToken"
    fi
}



# File was called directly, not sourced by another script
if [[ "${BASH_SOURCE[0]}" == "${BASH_SOURCE[ ${#BASH_SOURCE[@]} - 1 ]}" ]]; then
    hdVid "$@"
fi
