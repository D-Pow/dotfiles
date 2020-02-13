# Employee ID: 147783

# Program paths
export APACHE_HOME=/Applications/apache-maven-3.2.5/bin
export GRADLE_4_HOME=/opt/gradle/gradle-4.5.1/bin
export GRADLE_HOME=/opt/gradle/gradle-6.0.1/bin
export SUBLIME_HOME=/Applications/Sublime\ Text.app/Contents/SharedSupport/bin
export SUBLIME_DIR=/Users/dpowell1/Library/Application\ Support/Sublime\ Text\ 3/Packages/User/
export JAVA_HOME=/Library/Java/JavaVirtualMachines/jdk1.8.0_192.jdk/Contents/Home/
export BOOST_HOME=/usr/local/boost_1_67_0
export PIP3_HOME=/Users/dpowell1/Library/Python/3.6/bin
export PIP2_HOME=/Users/dpowell1/Library/Python/2.7/bin
export PATH=$PIP3_HOME:$PIP2_HOME:$JAVA_HOME:$APACHE_HOME:$GRADLE_HOME:$GRADLE_4_HOME:$SUBLIME_HOME:$BOOST_HOME:/usr/local/bin:/Users/dpowell1/bin:$PATH

# node-sass binary (since `npm install node-sass` always fails on post-install script)
export SASS_BINARY_PATH=/Users/dpowell1/repositories/binaries/node-sass-binary.node

# Colored terminal
# export PS1="\[\033[36m\]\u\[\033[m\]@\[\033[32m\]\h:\[\033[33;1m\]\w\[\033[m\]\$ "
export PS1="\[\033[36m\]\u\[\033[m\]:\[\033[33;1m\]\w\[\033[m\]\$ "
export CLICOLOR=1
export LSCOLORS=GxFxBxDxCxegedabagacad

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


copy() {
    echo -n "$1" | pbcopy
}


alias python='python3'
alias python2='/usr/bin/python'
alias devcurl="curl --noproxy '*'"
alias gradle4="$GRADLE_4_HOME/gradle"


resetJetbrains() {
    cd ~/Library/Preferences/
    rm jetbrains.* com.jetbrains.*
    rm -rf WebStorm2019.3/eval/ WebStorm2019.3/options/other.xml IntelliJIdea2019.3/eval/ IntelliJIdea2019.3/options/options.xml
}


alias rmpom='find . -name "pom.xml" -type f -delete'
alias pomgen='mvn pomgenerator:generate'
alias mvnsetup='chmod a+x setup.py && ./setup.py'
alias mvninstall='mvn clean install -Dmaven.javadoc.skip=true -DskipTests' #Add -U to force download from nexus
alias mvntest='mvn clean install -Dmaven.javadoc.skip=true'
alias spainstall='mvn clean install -Dmaven.javadoc.skip=true -DskipTests -Puat'
alias buildMutualFundsAIP='rmpom && pomgen && mvnsetup && mvninstall'

cf() {
    touch "$1" && chmod a+x "$1"
}

sitMfUsernames=(
    'ACKP4100' # Owns aggressive portfolio under account 5212
    'SREENI_REBRAND' 'sreeni_ap' 'nambi9' 'ABEK2800' 'ABZM8200' 'SIT-AJ-510' 'AAYR3600' 'TZ529300' 'ABAN3400' 'ABDV0100' 'ABED5900' 'TL858500'
    )
uatMfUsernames=('nambi9' 'op282200')
sitAipUsernames=(
    'ADBX9200' #has many held funds
    'ACUC0200'
    'ACWU1700' #CAP 1 with both brokerage and IRA accounts
    'ACTG0100' #can modify endDate in fromolaaip0403
    'ACYA2700' #has multiple completed plans and endDate plans
    'NAMBI-105'
    'NAMBI-210'
    'ACTZ9600'
    'ACTG0100' #owns GTLOX
    'ACUA4900' #CAP 1 with IRA account
    'ACVV7200' #CAP 1 with transaction fee funds
    'ACWC9100' #CAP 1 with transaction fee funds
    'ACUX4000' #CAP 1 account, noazx is fund for it
    'ACGL4100' #no accounts
    'AAVW3300' #no accounts
    'ACCN9200' #no accounts
)
uatAipUsernames=(
    'BCXH8500' #has IRA
    'BFCV1900' #CAP 1, owns fund ANIAX
    'BEVL7000'
    'BETX0800'
    'BETX1000'
)
capUsernames=('ACTJ3500' 'ACPE2900' 'ABZM8200')

alias mas="copy ${sitMfUsernames[0]}"
alias sit="copy ${sitAipUsernames[0]}"
alias uat="copy ${uatAipUsernames[0]}"
alias cap="copy ${capUsernames[0]}"


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

# SIT Shutdown Sequence:
#   edna -c stop -d sit-wm-s2-mfetf
#   edna -c stop -d sit-wm-s2core-mfetf
# Restart Sequence:
#   edna -c start -d sit-wm-s2core-mfetf
#   edna -c start -d sit-wm-s2-mfetf

# Look at logs
# tail -f *mutualFundEtf.log

gckb() {
    repoName="$(getGitRepoName)"

    if [ "$repoName" == "react-mutualfundsandetf" ]; then
        git checkout feature/PrebuiltxAIP-controls
    elif [ "$repoName" == "react-aip" ]; then
        git checkout feature/baseline-prebuiltmvp
    elif [ "$repoName" == "mutual_fund_etf" ]; then
        git checkout feature/baseline-aip-prebuilt
    fi
}

# Make bash autocomplete when tabbing after "git commit" alias like gc or gac
autocompleteWithJiraTicket() {
    # sed -rEgex 'substitute|pattern|\1 = show-only-match|'
    branch=$(getGitBranch | sed -E 's|.*/([A-Z]+-[0-9]+).*|\1|')
    COMPREPLY=$branch
    return 0
}
# Requires alias because spaces aren't allowed
complete -F autocompleteWithJiraTicket -P \" "gc"
complete -F autocompleteWithJiraTicket -P \" "gac"

# Make bash only display the options (not autocomplete) by using compgen
autocompleteWithAllGitBranches() {
    COMPREPLY=($(compgen -W '$(git branch)'))
    return 0
}
#complete -F autocompleteWithAllGitBranches "gck"
