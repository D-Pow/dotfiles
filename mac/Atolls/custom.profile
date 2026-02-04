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



commissionPull() {
    npm run contract:pull -- --registry platform-schema-registry --region eu-central-1 "$@"
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
