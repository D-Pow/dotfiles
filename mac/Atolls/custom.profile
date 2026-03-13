# Source Mac itself before this custom one
_macGeneralDir="$(realpath "$(thisDir)/..")"
source "$_macGeneralDir/custom.profile"

# Source private env vars not to be committed
_atollsDir="$(realpath "$(thisDir)")"
source "$_atollsDir/.env.profile"


export NPM_TOKEN="$GITLAB_TOKEN"
export npm_registry_token="$NPM_TOKEN"  # For payout-ui
export DOCKER_TOKEN="$GITLAB_TOKEN"  # Login via: echo "$DOCKER_TOKEN" | docker login registry.example.com -u <username> --password-stdin

export AWS_REGION='eu-central-1'

# For repo: commission-service-app
export AURORA_DB_NAME=app
export AURORA_DB_USERNAME=app  # super_tables_gsg
export AURORA_DB_PASSWORD=app
export AURORA_CLUSTER_ENDPOINT=localhost
export AURORA_READER_ENDPOINT=localhost
export DAPR_OUTPUT_BINDING_NAME=commission-service-app-sns-commission
export DAPR_OUTPUT_BINDING_OPERATION=create
export LEDGER_SERVICE_APP_ID=commission-service-app
export GRAPHQL_ENDPOINT=http://localhost:5000
export LOCALSTACK_ENDPOINT=http://localhost:4566
export REST_API_ENDPOINT=http://localhost:3000
export LOG_LEVEL='debug'
export LOG_FORMAT='json'
export MOCK_CONTROLLERS=true



devAwsAuth() {
    # See:
    #   - https://docs.aws.amazon.com/cdk/v2/guide/configure-access-sso-example-cli.html
    # aws configure sso --profile payout --region eu-central-1 --output json
    aws sso login --profile payout
}

devMySql() {
    docker-compose exec mysql mysql -u $AURORA_DB_USERNAME -p $AURORA_DB_PASSWORD "$@"
}

devTestApi() {
    docker-compose exec application npm run test:api -- "$@"
}

devNpmI() {
    npm i && docker-compose exec application npm i && git checkout -- package-lock.json
}

devDockerLogin() {
    echo $DOCKER_TOKEN | docker login registry.gitlab.com -u @devon.powell --password-stdin
}

dcea() {
    docker compose exec application "$@"
}

devSendSqsMessageInLocalstack() {
    declare sqsMessage="$1"

    declare origIFS="$IFS"
    declare IFS=$'\n'
    # Get AWS SQS queue URLs
    declare sqsUrls=($(
        docker compose exec localstack awslocal sqs list-queues \
        | jq -r '.QueueUrls[]'
    ))
    IFS="$origIFS"

    echo -e 'Which SQS URL do you want to send to?\n'

    declare PS3='Enter the SQS URL option number: '
    declare sqsUrlSelected=
    select sqsUrlSelected in "${sqsUrls[@]}"; do
        # See: https://linuxize.com/post/bash-select/
        break
    done

    # See: https://docs.localstack.cloud/aws/services/sqs/
    docker compose exec localstack awslocal sqs send-message \
        --queue-url "$sqsUrlSelected" \
        --message-body "$sqsMessage"
}



# Accessing DBs
# Use platform_fulfillment_dev
# Must use Sequel Ace because password must be in clear text and that isn't supportd in DBeaver:
#   https://www.reddit.com/r/dbeaver/comments/11skvfh/is_it_possible_to_connect_db_without_ssl_and_at/

devDbPassword() {
    declare defaultDbToUse=ledger
    declare dbToUse=

    read -p "Which DB (ledger|commission|payout) (default=$defaultDbToUse)? " dbToUse
    dbToUse="${dbToUse:-$defaultDbToUse}"

    declare dbHostname=
    declare dbUsername=

    if [[ "$dbToUse" == 'commission' ]]; then
        # Commission: Decides what discount customers get and provides commission to them
        dbHostname=commission-service-app-p8uzvc2s.cluster-cp0eg84aenmr.eu-central-1.rds.amazonaws.com
        dbUsername=rds-commission-service-app
    elif [[ "$dbToUse" == "ledger" ]]; then
        # Ledger: Transaction information, history, etc.
        dbHostname=ssp-ledger-service-app-emosomsm-db1.cp0eg84aenmr.eu-central-1.rds.amazonaws.com
        dbUsername=rds-ssp-ledger-service-app
    elif [[ "$dbToUse" == 'payout' ]]; then
        # Payout-processor: If a payout was requested and is in pending, success, or rejected status
        dbHostname=payout-processor-service-d5iig93q.cluster-cp0eg84aenmr.eu-central-1.rds.amazonaws.com
        dbUsername=rds-payout-processor-service
    fi

    declare dbPassword="$(
        aws rds generate-db-auth-token \
            --profile payout \
            --port 3306 \
            --region=eu-central-1 \
            --hostname "$dbHostname" \
            --username "$dbUsername"
    )"

    copy "$dbPassword"
    echo "$dbPassword"
}
