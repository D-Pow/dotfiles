npms() {
    # regex is homemade ~/bin/regex python script
    regex '"scripts": [^\}]*\}' ./package.json
}

alias npmr='npm run'
alias npmrtf="npm run test 2>&1 | egrep -o '^FAIL.*'" # only print filenames of suites that failed
alias npmPackagesWithVulns="npm audit | grep 'Dependency of' | sort -u | egrep -o '\S+(?=\s\[\w+\])'"


export NVM_DIR="$HOME/.nvm"
# Load nvm
[ -s "$NVM_DIR/nvm.sh" ] && source "$NVM_DIR/nvm.sh"
# Load nvm bash_completion
[ -s "$NVM_DIR/bash_completion" ] && source "$NVM_DIR/bash_completion"
export NVM_SYMLINK_CURRENT=true # Makes a symlink at ~/.nvm/current/bin/node so you don't have to chage IDEs' configurations when changing node versions



### Docker ###
dockerFindByName() {
    local imageName="$1"

    shift

    echo "`docker ps -a "$@" --filter "name=$imageName"`"
}

dockerIsContainerRunning() {
    local imageId="`dockerFindByName "$1" -q`"

    docker inspect --format '{{json .State.Running}}' "$imageId"
}
