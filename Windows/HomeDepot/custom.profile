declare _bashSubsystemDir="${dotfilesDir}/Windows/bash_subsystem"
declare _bashSubsystemProfile="${_bashSubsystemDir}/custom.profile"

source "$_bashSubsystemProfile"


export ARTIFACTORY_USER="$(jq -r '.user' "${reposDir}/maven-token.json")"
export ARTIFACTORY_TOKEN="$(jq -r '.access_token' "${reposDir}/maven-token.json")"
export NPM_TOKEN="$(jq -r '.access_token' "${reposDir}/npm-token.json")"
