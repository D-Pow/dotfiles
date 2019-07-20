# Employee ID: 147783

# Program paths
export APACHE_HOME=/Applications/apache-maven-3.2.5/bin
export GRADLE_HOME=/opt/gradle/gradle-4.5.1/bin
export SUBLIME_HOME=/Applications/Sublime\ Text.app/Contents/SharedSupport/bin
export SUBLIME_DIR=/Users/dpowell1/Library/Application\ Support/Sublime\ Text\ 3/Packages/User/
export JAVA_HOME=/Library/Java/JavaVirtualMachines/jdk1.8.0_192.jdk/Contents/Home/
export BOOST_HOME=/usr/local/boost_1_67_0
export PIP3_HOME=/Users/dpowell1/Library/Python/3.6/bin
export PIP2_HOME=/Users/dpowell1/Library/Python/2.7/bin
export user_bin=/Users/dpowell1/bin
export PATH=$user_bin:$PIP3_HOME:$PIP2_HOME:$JAVA_HOME:$APACHE_HOME:$GRADLE_HOME:$SUBLIME_HOME:$BOOST_HOME:/usr/local/bin:$PATH

# node-sass binary (since `npm install node-sass` always fails on post-install script)
export SASS_BINARY_PATH=/Users/dpowell1/repositories/binaries/node-sass-binary.node

# Colored terminal
# export PS1="\[\033[36m\]\u\[\033[m\]@\[\033[32m\]\h:\[\033[33;1m\]\w\[\033[m\]\$ "
export PS1="\[\033[36m\]\u\[\033[m\]:\[\033[33;1m\]\w\[\033[m\]\$ "
export CLICOLOR=1
export LSCOLORS=GxFxBxDxCxegedabagacad
alias ls='ls -Fh'

workMode='true'
# workMode='false'
if [ "$workMode" = "true" ]; then
    # Run proxy
    cntlmIsRunning=$(lsof -Pn -i4 | grep cntlm)
    if [[ -z $cntlmIsRunning ]]; then
        cntlm
    fi
    #DEV: iadwg-lb.corp.etradegrp.com
    #PRD: atlwg-lb.corp.etradegrp.com
    #export http_proxy=http://user:pass@iadwg-lb.corp.etradegrp.com:9090/
    export http_proxy=http://localhost:3128
    export HTTP_PROXY=$http_proxy
    export https_proxy=$http_proxy
    export HTTPS_PROXY=$http_proxy
else
    killall cntlm
    unset http_proxy
    unset HTTP_PROXY
    unset https_proxy
    unset HTTPS_PROXY
fi



alias lah='ls -lah'
alias python='python3'
alias python2='/usr/bin/python'
alias devcurl="curl --noproxy '*'"
alias editprofile="subl -n -w ~/.profile && source ~/.profile"


alias rmpom='find . -name "pom.xml" -type f -delete'
alias pomgen='mvn pomgenerator:generate'
alias mvnsetup='chmod a+x setup.py && ./setup.py'
alias mvninstall='mvn clean install -Dmaven.javadoc.skip=true -DskipTests -U'
alias buildMutualFundsAIP='rmpom && pomgen && mvnsetup && mvninstall'

cf() {
    touch "$1" && chmod a+x "$1"
}

npms() {
    # regex is homemade ~/bin/regex python script
    regex '"scripts": [^\}]*\}' ./package.json
}
alias npmr='npm run'
alias grep='grep --exclude-dir={node_modules,.git,.idea,lcov-report}'
alias egrep='egrep --exclude-dir={node_modules,.git,.idea,lcov-report}'
gril() {
    grep "$1" -ril .
}

sitUsernames=('SREENI_REBRAND' 'sreeni_ap' 'nambi9' 'ABEK2800' 'ABZM8200' 'SIT-AJ-510' 'AAYR3600' 'TZ529300' 'ABAN3400' 'ABDV0100' 'ABED5900' 'TL858500')
uatUsernames=('nambi9' 'op282200')
sitBetaUsernames=(
    'NAMBI-105'
    'NAMBI-210'
    'ACTZ9600'
    'ACUC0200'
    'ACTG0100' #can modify endDate in fromolaaip0403
    'ACWU1700' #CAP 1 with both brokerage and IRA accounts
    'ACTG0100' #owns GTLOX
    'ACUA4900' #CAP 1 with IRA account
    'ACVV7200' #CAP 1 with transaction fee funds
    'ACWC9100' #CAP 1 with transaction fee funds
    'ACUX4000' #CAP 1 account, noazx is fund for it
    'ACGL4100' #no accounts
    'AAVW3300' #no accounts
    'ACCN9200' #no accounts
)
uatBetaUsernames=(
    'BFCV1900' #CAP 1, owns fund ANIAX
    'BEVL7000'
    'BCXH8500'
    'BETX0800'
    'BETX1000'
)
capUsernames=('ACTJ3500' 'ACPE2900' 'ABZM8200')

copy() {
    echo -n "$1" | pbcopy
}
sitCopy() {
    copy "${sitUsernames[$1]}"
}
uatCopy() {
    copy "${uatUsernames[$1]}"
}
alias sit='sitCopy 2'
alias aip='sitCopy 1'
alias mas='sitCopy 2'
alias uat='uatCopy 0'
alias cap="copy ${capUsernames[0]}"
alias beta="copy ${sitBetaUsernames[5]}"
alias betauat="copy ${uatBetaUsernames[0]}"


# webapp -> em.properties
# S2_DEFAULT_AMQP_ADDRESS=tcp:localhost:5672
# S2_DEFAULT_AMQP_AUTH=guest:guest
alias start_rabbit='/Applications/rabbitmq_server-3.3.5/sbin/rabbitmq-server start-server'
alias start_tomcat='/Applications/apache-tomcat-8.0.3/bin/startup.sh'
alias stop_tomcat='/Applications/apache-tomcat-8.0.3/bin/shutdown.sh'
export rabbit_url='http://localhost:15672/#/'
export tomcat_url='http://localhost:8081/manager/html'
# login tomcat1/tomcat1
# When you're running both, before you even start your s2 service locally you should see
# in tomcat s2core-webapp running and in rabbit queues for Ping, S2MetaDataService,xLocDBInfoGet
# Then when you start your service you should see queues for it as well


# SIT and UAT boxes
essh() {
    ssh "$1.etrade.com"
}
# sit:wm:s2:mfetf
export sit1='sit390w224m7'
export sit2='sit429w86m7'
# uat:wm:s2:mfetf
export uat1='uat345w92m7'
export uat2='uat370w228m7'
# Norm's sit boxes
export norm1='sit215w86m7'
export norm2='sit241w80m7'

#SIT Shutdown Sequence:
#edna -c stop -d sit-wm-s2-mfetf
#edna -c stop -d sit-wm-s2core-mfetf
#Restart Sequence:
#edna -c start -d sit-wm-s2core-mfetf
#edna -c start -d sit-wm-s2-mfetf

export bl='feature/baseline-R3'

alias    g='git'
alias   gs='git status'
alias   gd='git diff'
alias  gdc='git diff --cached'
alias   ga='git add'
alias  gap='git add -p'
alias   gc='git commit -m'
alias  gca='git commit --amend'
alias  gac='git commit -am'
alias   gb='git branch'
alias  gbd='git branch -d $(git branch | grep -v "*")'
alias  gck='git checkout'
alias gckb="git checkout $bl"
alias   gl='git log --stat --graph'
alias  glo='git log --stat --graph --oneline'
alias  gla='git log --stat --graph --oneline --all'
alias   gp='git push'
alias   gr='git reset'
alias  grH='git reset HEAD'
alias  grh='git reset --hard'
alias grhH='git reset --hard HEAD'
alias  gpl='git pull'
alias  gst='git stash'
alias gsta='git stash apply'
alias gsts='git stash save'
alias  gau='git update-index --assume-unchanged'
alias gnau='git update-index --no-assume-unchanged'
alias  gaud='git update-index --assume-unchanged src/data/mocks/DefaultPageConfig.js'
alias gnaud='git update-index --no-assume-unchanged src/data/mocks/DefaultPageConfig.js'
alias gcmd='cat ~/.profile | grep -e "alias *g" | grep -v "grep"'

# Open merge conflict files
gcon() {
    subl $(gs | grep both | sed 's|both modified:||')
}

# Make bash autocomplete when tabbing after "git commit" alias like gc or gac
getGitBranch() {
    # sed -rEgex 'substitute|pattern|show-only-matching|'
    branch=$(git branch | grep '*' | sed -E 's|.*/([A-Z]+-[0-9]+).*|\1|')
    if [[ $branch = *"feature/"* ]]; then
        branch=$(echo $branch | cut -c 9-20)
    fi
    COMPREPLY=$branch
    return 0
}
# Requires alias because spaces aren't allowed
complete -F getGitBranch "gc"
complete -F getGitBranch "gac"

# Make bash only display the options (not autocomplete) by using compgen
getGitBranches() {
    COMPREPLY=($(compgen -W '$(git branch)'))
    return 0
}
#complete -F getGitBranches "gck"
