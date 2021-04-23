# Employee ID: 147783
# IntelliJ license link: https://account.jetbrains.com/a/a1fwiqa3
# WebStorm license link: https://account.jetbrains.com/a/5vmhuqob

# Program paths
export MAVEN_HOME=/Applications/apache-maven-3.6.3/bin
export GRADLE_4_HOME=/opt/gradle/gradle-4.5.1/bin
export GRADLE_HOME=/opt/gradle/gradle-6.0.1/bin
export SUBLIME_HOME=/Applications/Sublime\ Text.app/Contents/SharedSupport/bin
export SUBLIME_DIR=/Users/dpowell1/Library/Application\ Support/Sublime\ Text\ 3/Packages/User/
export JAVA_HOME=/Library/Java/JavaVirtualMachines/jdk1.8.0_192.jdk/Contents/Home/
export BOOST_HOME=/usr/local/boost_1_67_0
export PIP3_HOME=/usr/local/opt/python\@3.7/bin/
export PIP2_HOME=/Users/dpowell1/Library/Python/2.7/bin
export PATH=$PIP3_HOME:$PIP2_HOME:$JAVA_HOME:$MAVEN_HOME:$GRADLE_HOME:$GRADLE_4_HOME:$SUBLIME_HOME:$BOOST_HOME:/usr/local/bin:/Users/dpowell1/bin:$PATH

# Colored terminal
# export PS1="\[\033[36m\]\u\[\033[m\]@\[\033[32m\]\h:\[\033[33;1m\]\w\[\033[m\]\$ "
export PS1="\[\033[36m\]\u\[\033[m\]:\[\033[33;1m\]\w\[\033[m\]\$ "
export CLICOLOR=1
export LSCOLORS=GxFxBxDxCxegedabagacad

[[ -s $HOME/.nvm/nvm.sh ]] && source $HOME/.nvm/nvm.sh

alias python='python3'
alias python2='/usr/bin/python'
export PIP_INDEX_URL='https://artifactory.etrade.com/artifactory/api/pypi/pypi/simple'

alias devcurl="curl --noproxy '*'"
alias gradle4="$GRADLE_4_HOME/gradle"

# E-Trade uses its own hosted npm registry; as such, the registry needs to be set
#  to find the private E-Trade packages.
# Similarly, since the registry is changed, `npm install node-sass` always fails on post-install script,
#  so the SASS binary site needs to be set as well (see https://github.com/sass/node-sass/tree/master#binary-configuration-parameters).
# This can be done via repo-root-level .npmrc file with entries:
#  registry=https://repo.etrade.com/registry/npm/npm-all/
#  sass_binary_site=https://artifactory.etrade.com/artifactory/github/sass/node-sass/releases/download
# Or it can be done using this alias
alias enpm='npm --registry="https://repo.etrade.com/registry/npm/npm-all/" --sass-binary-site="https://artifactory.etrade.com/artifactory/github/sass/node-sass/releases/download"'


copy() {
    echo -n "$1" | pbcopy
}


resetJetbrains() {
    cd ~/Library/Preferences/
    rm jetbrains.* com.jetbrains.*
    rm -rf WebStorm2019.3/eval/ WebStorm2019.3/options/other.xml IntelliJIdea2019.3/eval/ IntelliJIdea2019.3/options/options.xml
}


toggleProxy() {
    if [ "$1" = "on" ]; then
        echo 'Activating cntlm with proxy to "http://localhost:3128"'
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
    elif [ "$1" = "off" ]; then
        echo 'Deactivating cntlm and unsetting proxy'
        killall cntlm
        unset http_proxy
        unset HTTP_PROXY
        unset https_proxy
        unset HTTPS_PROXY
    else
        echo 'Usage: toggleProxy [on|off]'
    fi
}


mvntestfileinsubmodule() {
    mvn test -Dtest=$1
}

alias rmpom='find . -name "pom.xml" -type f -delete'
alias pomgen='mvn pomgenerator:generate'
alias mvnsetup='chmod a+x setup.py && ./setup.py'
alias mvninstall='mvn clean install -Dmaven.javadoc.skip=true -DskipTests' #Add -U to force download from nexus
alias mvntest='mvn clean install -Dmaven.javadoc.skip=true'
alias mvntestsubmodule='mvn test -pl'
alias spainstall='mvn clean install -Dmaven.javadoc.skip=true -DskipTests -Puat'
alias buildMutualFundsAIP='mvnsetup'

cf() {
    touch "$1" && chmod a+x "$1"
}

sitMfUsernames=(
    'ACKP4100' # Owns aggressive portfolio under account 5212
    'SREENI_REBRAND' 'sreeni_ap' 'nambi9' 'ABEK2800' 'ABZM8200' 'SIT-AJ-510' 'AAYR3600' 'TZ529300' 'ABAN3400' 'ABDV0100' 'ABED5900' 'TL858500'
    )
uatMfUsernames=('nambi9' 'op282200')
sitAipUsernames=(
    'AGVY2400' #can place an order in Prebuilt
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
    'BLXF9400' #has reg-bi beta flag
    'BCXH8500' #has IRA
    'BFCV1900' #CAP 1, owns fund ANIAX
    'BEVL7000'
    'BETX0800'
    'BETX1000'
)
capUsernames=('ACTJ3500' 'ACPE2900' 'ABZM8200')
prdUsernames=(
    'qatest_02' # password (Test@234) - do NOT place prebuilt order
)

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
# All SIT instances
# sit:wm:s2:mfetf:sit429w86m7
# sit:wm:s2:mfetf:sit390w224m7
# sit:cs:s2:mfetf:sit175w186m7
# sit:cs:s2:mfetf:sit172w188m7
export sit1='sit390w224m7'
export sit2='sit429w86m7'
# uat:wm:s2:mfetf
export uat1='uat345w92m7'
export uat2='uat370w228m7'
# Norm's sit boxes
# sit:rb:s2:aip:sit215w86m7
# sit:rb:s2:aip:sit241w80m7
# sit:rb:s2:csaip:sit141w86m7
# sit:rb:s2:csaip:sit50w80m7
export norm1='sit215w86m7'
export norm2='sit241w80m7'
# DB boxes
export sitdb1='sit108w80m7'
export sitdb2='sit141w86m7'
# sit:ets:batch:ord for batch jobs
export cbassbatch='sit108w80m7'

alias mountbatchserver='sshfs dpowell1@sit108w80m7.etrade.com:/ ~/cbass_batch/'
alias unmountbatchserver='umount -f ~/cbass_batch/'

# PRD login through Jump Hosts
# Uses LDAP password + Symantec VIP token
# Symantec VIP token gotten from:
#   1. Install app from your phone's app store
#   2. Authenticate your phone's Symantec ID by going to  https://symantec.etrade.com/  (Found from <https://channele.corp.etradegrp.com/mywork/technical-support/_layouts/15/WopiFrame.aspx?sourcedoc=/mywork/technical-support/Documents/Logon-Portal-Instructions.docx&action=default&DefaultItemOpen=1>  ->  <https://employeelogin.etrade.com/profile> which redirects to <https://employeelogin.etrade.com/eauth/XUI/?realm=/employees#dashboard/>)
# More info at: https://confluence.corp.etradegrp.com/pages/viewpage.action?pageId=205997157
export loginprd='ssh dpowell1@ssh.etrade.com'

alias dvl='ssh lxdm7876m53.etrade.com'

# SIT Shutdown Sequence:
#   edna -c stop -d sit-wm-s2-mfetf
#   edna -c stop -d sit-wm-s2core-mfetf
# Restart Sequence:
#   edna -c start -d sit-wm-s2core-mfetf
#   edna -c start -d sit-wm-s2-mfetf

# Look at logs
# tail -f *mutualFundEtf.log

alias  gaud='git update-index --assume-unchanged src/data/mocks/DefaultPageConfig.js'
alias gnaud='git update-index --no-assume-unchanged src/data/mocks/DefaultPageConfig.js'

gckb() {
    repoName="$(getGitRepoName)"

    if [ "$repoName" == "react-mutualfundsandetf" ]; then
        git checkout feature/baseline-income-portfolio
    elif [ "$repoName" == "react-aip" ]; then
        git checkout feature/baseline-etf-aip
    elif [ "$repoName" == "mutual_fund_etf" ]; then
        git checkout feature/baseline-etf-aip-mvp-2
    elif [ "$repoName" == "aip_java8" ]; then
        git checkout feature/baseline-aipetf-mvp
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
