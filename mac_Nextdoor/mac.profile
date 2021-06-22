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

alias python='python3'
alias python2='/usr/bin/python'
# export PIP_INDEX_URL='https://artifactory.etrade.com/artifactory/api/pypi/pypi/simple'

alias devcurl="curl --noproxy '*'"
alias gradle4="$GRADLE_4_HOME/gradle"


copy() {
    echo -n "$1" | pbcopy
}


getAppBinaryPath() {
    # lsappinfo - gets all info for a *running* app
    # It's more robust than other solutions for getting the absolute path to the MyApp.app's binary file
    # local plistKeys=( 'binary'='CFBundleExecutable' 'binary2'='CFBundleExecutablePath' )
    local binaryPath="$(lsappinfo info -app "$1" -only CFBundleExecutablePath | sed -E 's/"|.*=//g')"

    # echo "${plistKeys['binary2']}"

    if ! [[ -z "${binaryPath}" ]]; then
        # App is running, so we have safely found the absolute path
        echo "$binaryPath"
        return 0
    else
        # App is not running, so we have to manually generate the absolute path

        # osascript is AppleScript. It's annoying, but required to get the app ID
        # `mdfind` is basically the terminal's version of Spotlight (Cmd+Space search system)
        #     `mdfind` is faster than `find` b/c it doesn't search all files everywhere, only those specified with the search criteria
        # `mdls [-raw -name kMD_keyword] $appPath` - Gets app details, not including absolute paths for anything
        #
        # Once we have the app ID/path, we need to read the info about it to get the executable.
        # `defaults read -app 'App Name'` - seems to work sometimes but not always
        #     Reading the app's Info.plist seems to work well, though
        # `lsregister` - Gets even more info about an app
        #     Not on PATH, need to call directly from: /System/Library/Frameworks/CoreServices.framework/Versions/A/Frameworks/LaunchServices.framework/Versions/A/Support/lsregister
        #     or `mdfind -name lsregister`
        local appId="$(osascript -e "id of app \"$1\"")"

        if ! [[ -z "${appId}" ]]; then
            local appPath="$(mdfind "kMDItemCFBundleIdentifier == $appId" | head -n 1)"

            if ! [[ -z "${appPath}" ]]; then
                local appRelativeRootDir='Contents'
                local appRelativeExecutableDir='MacOS'
                local binaryName="$(defaults read "$appPath/$appRelativeRootDir/Info" CFBundleExecutable)"

                binaryPath="$appPath/$appRelativeRootDir/$appRelativeExecutableDir/$binaryName"

                echo "$binaryPath"
                return 0
            fi
        fi
    fi

    return 1  # can't do `exit 1` since this is in .profile (instead of a script file) and `exit` would close the terminal
}


resetJetbrains() {
    cd ~/Library/Preferences/
    rm jetbrains.* com.jetbrains.*
    rm -rf WebStorm2019.3/eval/ WebStorm2019.3/options/other.xml IntelliJIdea2019.3/eval/ IntelliJIdea2019.3/options/options.xml
}


mvntestfileinsubmodule() {
    mvn test -Dtest=$1
}

alias rmpom='find . -name "pom.xml" -type f -delete'
alias pomgen='mvn pomgenerator:generate'
alias mvnsetup='rmpom && pomgen'
alias mvninstall='mvn clean install -Dmaven.javadoc.skip=true -DskipTests' #Add -U to force download from nexus
alias mvntest='mvn clean install -Dmaven.javadoc.skip=true'
alias mvntestsubmodule='mvn test -pl'


cf() {
    touch "$1" && chmod a+x "$1"
}


alias nxtdr='cd ~/repositories/nextdoor.com/apps/nextdoor/frontend'

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
