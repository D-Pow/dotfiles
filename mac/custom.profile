### Which nested `mac/` environment's .profile should be sourced ###
# Source it at the end to ensure all Mac defaults are included/defined first
CURRENT_ENV='Nextdoor'


### Program paths ###

export SUBLIME_HOME=/Applications/Sublime\ Text.app/Contents/SharedSupport/bin
export SUBLIME_DIR=/Users/dpowell1/Library/Application\ Support/Sublime\ Text/Packages/User/
export JAVA_HOME=/Library/Java/JavaVirtualMachines/jdk1.8.0_291.jdk/Contents/Home/
export TEXMFHOME=/Users/dpowell/texlive/2021/bin/universal-darwin

# Run: brew install bash coreutils gawk gnutls gnu-indent gnu-getopt gnu-sed gnu-tar grep findutils
# Then, add `/usr/local/bin/bash` to `/etc/shells`
# Then, set default bash for all users (including root): sudo chsh -s /usr/local/bin/bash
_brewGnuUtils=(
    bash
    coreutils
    gawk
    gnutls
    gnu-indent
    gnu-getopt
    gnu-sed
    gnu-tar
    grep
    findutils
)
_brewGnuUtilsHomePrefix=/usr/local/opt
_brewGnuUtilsHomeSuffix=libexec/gnubin
for (( i=0; i < "${#_brewGnuUtils[@]}"; i++ )); do
    _gnuApp="${_brewGnuUtils[i]}"
    _brewGnuUtils[i]="$_brewGnuUtilsHomePrefix/$_gnuApp/$_brewGnuUtilsHomeSuffix"
done
BREW_GNU_UTILS_HOMES="`array.join -s _brewGnuUtils ':'`"

_brewPathEntries="$(echo "$BREW_PATHS" | sed -E 's/\s+/:/g')" # /usr/local/sbin and some others

export PATH=$BREW_GNU_UTILS_HOMES:$JAVA_HOME:$SUBLIME_HOME:$TEXMFHOME:/usr/local/bin:$HOME/bin:$_brewPathEntries:$PATH


# Colored terminal
# export PS1="\[\033[36m\]\u\[\033[m\]@\[\033[32m\]\h:\[\033[33;1m\]\w\[\033[m\]\$ "
export PS1="\[\033[36m\]\u\[\033[m\]:\[\033[33;1m\]\w\[\033[m\]\$ "
export CLICOLOR=1
# Colors:
#   a (black), b (red), c (green), d (brown), e (blue), f (magenta), g (cyan), h (grey), x (no color).
#   Capital letter for bold, lowercase for normal.
#   First letter = text color, Second letter = background color.
# Order:
#   Dir, SymLink, Socket, Pipe, Exec, BlockSpecial, CharSpecial, ExecSetuid, ExecSetGID, DirSticky, DirNoSticky.
# Useful GUI: https://geoff.greer.fm/lscolors/
export LSCOLORS=gxfxcxdxbxxhxhbxbxGxGx
export LS_COLORS='di=36:ln=35:so=32:pi=33:ex=31:bd=0;47:cd=0;47:su=31:sg=31:tw=1;36:ow=1;36'


alias python='python3'
alias python2='/usr/bin/python'

alias devcurl="curl --noproxy '*'"


# Add --no-verify for git pushes since it takes forever and often dies half-way through
alias gp='git push --no-verify'
alias gpu='git push -u origin $(gitGetBranch) --no-verify'

alias todo="subl '~/Desktop/ToDo.md'"


_personalReposGitConfig="$(realpath "$dotfilesDir/../me/.gitconfig")"

if ! [[ -f "$_personalReposGitConfig" ]]; then
    # Allows overriding global .gitconfig by specifying the dirs where a different .gitconfig should be included in the global config.
    #   See: https://stackoverflow.com/questions/8337071/different-gitconfig-for-a-given-subdirectory/60344116#60344116
    echo "Add my custom .gitconfig file to $(dirname "$_personalReposGitConfig")/ and add the lines below AT THE END of the global .gitconfig to override Git configs for every repo in that directory. Copy everything from Linux's .gitconfig other than the \`[credential]\` section."
    echo '```
[includeIf "gitdir:~/src/me/"]
    path = ~/src/me/.gitconfig
```'
fi




cf() {
    touch "$1" && chmod a+x "$1"
}



alias getAllApps=`mdfind "kMDItemKind == 'Application'"`

getAppInfo() {
    declare USAGE="${FUNCNAME[0]} [-f] <app-name>
    Gets information about an app on Mac.
    Helps address some pain points about Mac's shortcomings when compared to Linux,
    e.g. finding where app executables are located for use in the terminal, finding where their files are stored, etc.

    Uses \`lsappinfo\` if the app is running (easy to read but provides less information).
    Uses a mix of \`mdfind\` and \`osascript\` (Apple script) otherwise to extract info from the Info.plist file.

    Options:
        -f      |   Force getting the full app info from the .plist even if the app is running.
    "

    declare _fullAppInfo=
    declare OPTIND=1

    while getopts 'f' opt; do
        case "$opt" in
            f)
                _fullAppInfo=true
                ;;
            *)
                echo -e "$USAGE"
                return 1
                ;;
        esac
    done

    shift $(( OPTIND - 1 ))

    declare app="$1"
    declare property="$2"

    # lsappinfo - gets all info for a *running* app
    # It's more robust than other solutions for getting the absolute path to the MyApp.app's binary file
    # local plistKeys=( 'binary'='CFBundleExecutable' 'binary2'='CFBundleExecutablePath' )
    # echo "${plistKeys['binary2']}"
    declare result=`lsappinfo info -app "$app"`

    if [[ -n "$result" ]] && [[ -z "$_fullAppInfo" ]]; then
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

        return
    fi


    # App is not running, so we have to manually generate the absolute path
    #
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
    declare appId="$(osascript -e "id of app \"$app\"")"

    if ! [[ -z "${appId}" ]]; then
        declare appPath="$(mdfind "kMDItemCFBundleIdentifier == $appId" | head -n 1)"

        if ! [[ -z "${appPath}" ]]; then
            if ! [[ -z "${property}" ]]; then
                declare binaryKey='CFBundleExecutable'

                if [ "$property" = "binary" ]; then
                    property=$binaryKey
                fi

                declare appRelativeRootDir='Contents'
                declare appRelativeExecutableDir='MacOS'
                declare propertyValue=`defaults read "$appPath/$appRelativeRootDir/Info" $property`

                if [ "$property" = "$binaryKey" ]; then
                    propertyValue="$appPath/$appRelativeRootDir/$appRelativeExecutableDir/$propertyValue"
                fi

                echo $propertyValue
            else
                # Note: Nest variables in quotes to read `\n` correctly
                declare allInfoJson=`osascript -s s -e "info for (POSIX file \"$appPath\")"`
                declare allInfoWithoutCurlyBraces=`echo "$allInfoJson" | sed -E 's|[{}]||g'`
                declare allInfoSplitIntoNewlines=`echo "$allInfoWithoutCurlyBraces" | sed -E 's|", |"\n|g'`
                declare allInfoWithSpacesBetweenKeyAndValAndIndent=`echo "$allInfoSplitIntoNewlines" | sed -E 's|^([^:]*):|    \1 = |g'`

                echo "$allInfoWithSpacesBetweenKeyAndValAndIndent"
            fi

            return
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
    rm -rf WebStorm*/eval/ WebStorm*/options/other.xml IntelliJIdea*/eval/ IntelliJIdea*/options/options.xml
}



# Make bash autocomplete when tabbing after "git commit" alias like gc or gac
_autocompleteWithJiraTicket() {
    # sed -rEgex 'substitute|pattern|\1 = show-only-match|'
    branch=$(gitGetBranch | sed -E 's|.*/([A-Z]+-[0-9]+).*|\1|')
    COMPREPLY=$branch
    return
}
# Requires alias because spaces aren't allowed
complete -F _autocompleteWithJiraTicket -P \" "gc"
complete -F _autocompleteWithJiraTicket -P \" "gac"



source "$(thisDir)/$CURRENT_ENV/custom.profile"
