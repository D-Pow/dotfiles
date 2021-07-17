# Employee ID: 147783
# IntelliJ license link: https://account.jetbrains.com/a/a1fwiqa3
# WebStorm license link: https://account.jetbrains.com/a/5vmhuqob

# Program paths
BREW_GNU_UTILS_HOME=/usr/local/opt/grep/libexec/gnubin # Run: brew install bash coreutils findutils gnu-tar gnu-sed gawk gnutls gnu-indent gnu-getopt grep
                                                       # Then, add `/usr/local/bin/bash` to `/etc/shells`
                                                       # Then, set default bash for all users (including root): sudo chsh -s /usr/local/bin/bash
export SUBLIME_HOME=/Applications/Sublime\ Text.app/Contents/SharedSupport/bin
export SUBLIME_DIR=/Users/dpowell1/Library/Application\ Support/Sublime\ Text/Packages/User/
export JAVA_HOME=/Library/Java/JavaVirtualMachines/jdk1.8.0_291.jdk/Contents/Home/
# export PIP3_HOME=/usr/local/opt/python\@3.7/bin/
# export PIP2_HOME=/Users/dpowell1/Library/Python/2.7/bin
export PATH=$BREW_GNU_UTILS_HOME:$PIP3_HOME:$PIP2_HOME:$JAVA_HOME:$MAVEN_HOME:$GRADLE_HOME:$GRADLE_4_HOME:$SUBLIME_HOME:$BOOST_HOME:/usr/local/bin:/Users/dpowell1/bin:$PATH

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


if [[ -z `command -v tree` ]]; then
    # `tree` isn't defined, so define it here
    tree() {
        local path="$1"

        if [[ -z "$path" ]]; then
            path='.'
        fi

        # `cd` into the directory to avoid extra slashes/nested `| ` text from appearing
        #   e.g. `tree ../dir/` would result in `find ../dir/` being called and resulting file/dir entries
        #   being printed as `../dir/file.txt` --> `| ├─file.txt` instead of `├─file.txt`
        # `find` doesn't add a trailing slash on directories by default, so add them manually via `printf`
        local allEntriesWithTrailingSlashOnDirsDirs="`(cd "$path" && find . -type d -exec sh -c 'printf "$0/\n"' {} \; -or -print)`"
        # Remove duplicate `//` when runing `tree someDir/` (no double slashes with `tree someDir`)
        local normalizedPaths="`echo "$allEntriesWithTrailingSlashOnDirsDirs" | sed -E "s#//#/#g"`"
        # Replace preceding `path/to/` in `path/to/file.txt` with `| | ├─file.txt` to match standard `tree path/` output.
        # sed -rEgex 'command-1; command-2'
        # command-1: Replace `some-text/` with `| ` repeatedly for however many nested parent dirs exist for the file.
        #   e.g. `dir1/dir2/file.txt` --> `| | file.txt`
        #   However, if the line ends with `/`, then don't replace the final trailing `/` since that entry is a directory.
        # command-2: Replace the final `| ` from the previous `| | file.txt` output with `├─` to show it's a file within that directory.
        #   e.g. `| | file.txt` --> `| ├─file.txt`
        local parentDirsReplacedWithTreeDelimiters="`echo "$normalizedPaths" | sed -E 's#[^/]*/([^/]*/$)?#| \1#g; s#\| ([^|])#├─\1#g'`"
        # Replace first line of output with the user-specified path since it's erased in the sed commands above
        local firstLineReplacedWithParentPath="`echo "$parentDirsReplacedWithTreeDelimiters" | sed -E "1 s|^.*$|$path|"`"

        echo "$firstLineReplacedWithParentPath"
    }
fi


# Add --no-verify for git pushes since it takes forever and often dies half-way through
alias gp='git push --no-verify'
alias gpu='git push -u origin $(getGitBranch) --no-verify'

alias todo="subl '~/Desktop/ToDo.md'"

alias nxtdr='cd ~/src/nextdoor.com/apps/nextdoor/frontend'

alias db-start-server='nd dev getdb'
alias db-login='psql nextdoor django1'

alias fix-sockets='nd dev update unix_socket_bridge'
alias fix-aws='aws_eng_login'

fe-start() {
    nxtdr

    local devProxyIsRunning="`dockerIsContainerRunning 'dev-local-proxy'`"

    if [[ $devProxyIsRunning != 'true' ]]; then
        nd dev portal
    fi

    yarn build --watch
}
fe-stop() {
    docker stop nextdoorcom_dev-local-proxy_1 nextdoorcom_dev-portal_1 nextdoorcom_static_1
}

be-start() {
    if ! aws sts get-caller-identity > /dev/null 2>&1; then
        fix-aws
        fix-sockets
    fi

    if ! curl https://static.localhost.com/ 2>/dev/null; then
        STATIC_CONTENT_HOST=https://static.localhost.com:443 NEXTDOOR_PORT=443 nd dev runserver
    fi
}
be-stop() {
    echo 'TODO'
}


copy() {
    echo -n "$1" | pbcopy
}

cf() {
    touch "$1" && chmod a+x "$1"
}



# alias getAllApps=`mdfind "kMDItemKind == 'Application'"`
getAppInfo() {
    local app="$1"
    local property="$2"

    # lsappinfo - gets all info for a *running* app
    # It's more robust than other solutions for getting the absolute path to the MyApp.app's binary file
    # local plistKeys=( 'binary'='CFBundleExecutable' 'binary2'='CFBundleExecutablePath' )
    # echo "${plistKeys['binary2']}"
    local result=`lsappinfo info -app "$app"`

    if ! [[ -z "${result}" ]]; then
        # App is running, so we have safely found correct property values, e.g. absolute path to binary vs just the binary name

        if ! [[ -z "${property}" ]]; then
            if [ "$property" = "binary" ]; then
                property='CFBundleExecutablePath'
            fi

            # Strip superfluous `key=` from `key=val` output
            result=`lsappinfo info -app "$app" -only "$property" | sed -E 's/"|.*=//g'`
        else
            # Add spaces around `key=val` pairs that don't have spaces to be consistent with those that do (b/c Mac is stupid and inconsistent)
            result=`echo "$result" | sed -E 's|([^ ])=([^ ])|\1 = \2|'` # no clue why, but `\S` doesn't work so use `[^ ]` instead
        fi

        echo "$result"

        return 0
    fi


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
            if ! [[ -z "${property}" ]]; then
                local binaryKey='CFBundleExecutable'

                if [ "$property" = "binary" ]; then
                    property=$binaryKey
                fi

                local appRelativeRootDir='Contents'
                local appRelativeExecutableDir='MacOS'
                local propertyValue=`defaults read "$appPath/$appRelativeRootDir/Info" $property`

                if [ "$property" = "$binaryKey" ]; then
                    propertyValue="$appPath/$appRelativeRootDir/$appRelativeExecutableDir/$propertyValue"
                fi

                echo $propertyValue
            else
                # Note: Nest variables in quotes to read `\n` correctly
                local allInfoJson=`osascript -s s -e "info for (POSIX file \"$appPath\")"`
                local allInfoWithoutCurlyBraces=`echo "$allInfoJson" | sed -E 's|[{}]||g'`
                local allInfoSplitIntoNewlines=`echo "$allInfoWithoutCurlyBraces" | sed -E 's|", |"\n|g'`
                local allInfoWithSpacesBetweenKeyAndValAndIndent=`echo "$allInfoSplitIntoNewlines" | sed -E 's|^([^:]*):|    \1 = |g'`

                echo "$allInfoWithSpacesBetweenKeyAndValAndIndent"
            fi

            return 0
        fi
    fi

    return 1  # can't do `exit 1` since this is in .profile (instead of a script file) and `exit` would close the terminal
}

getAppBinaryPath() {
    getAppInfo "$1" 'binary'
}


resetJetbrains() {
    cd ~/Library/Preferences/
    rm jetbrains.* com.jetbrains.*
    rm -rf WebStorm2019.3/eval/ WebStorm2019.3/options/other.xml IntelliJIdea2019.3/eval/ IntelliJIdea2019.3/options/options.xml
}



# Make bash autocomplete when tabbing after "git commit" alias like gc or gac
_autocompleteWithJiraTicket() {
    # sed -rEgex 'substitute|pattern|\1 = show-only-match|'
    branch=$(getGitBranch | sed -E 's|.*/([A-Z]+-[0-9]+).*|\1|')
    COMPREPLY=$branch
    return 0
}
# Requires alias because spaces aren't allowed
complete -F _autocompleteWithJiraTicket -P \" "gc"
complete -F _autocompleteWithJiraTicket -P \" "gac"