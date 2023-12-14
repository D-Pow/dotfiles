### Which nested `mac/` environment's .profile should be sourced ###
# Source it at the end to ensure all Mac defaults are included/defined first before company-/device-specific ones

_MAC_ENV_PERSONAL='Personal'
MAC_ENV="$_MAC_ENV_PERSONAL"

_macSpecificDir="$(thisDir)/$MAC_ENV"
_macSpecificProfile="$_macSpecificDir/custom.profile"

export PATH="$_macSpecificDir/bin:$PATH"

unalias editprofile
alias editprofile="_editProfile '$_macSpecificProfile'"



# Run: brew install ${_brewGnuUtils[@]}
# Then, add `/usr/local/bin/bash` to `/etc/shells`
# Then, set default bash for all users (including root): sudo chsh -s /usr/local/bin/bash
#
# Put this before other `PATH` modifications so standard GNU utils are available.
#
# See:
#   List of things to install: https://github.com/fabiomaia/linuxify/blob/6290bfe581b2b4dacc8d5526e6157594a5b2b331/linuxify#L37
#   Original StackOverflow thread: https://apple.stackexchange.com/questions/69223/how-to-replace-mac-os-x-utilities-with-gnu-core-utilities
_brewGnuUtils=(
    coreutils
    findutils
    binutils
    diffutils
    bash
    grep
    gawk
    gzip
    # screen
    watch
    gnutls
    gnu-indent
    gnu-getopt
    gnu-sed
    gnu-tar
    gnu-which
)
_brewGnuUtilsHomePrefix=/usr/local/opt
_brewGnuUtilsHomeSuffix=libexec/gnubin
for (( i=0; i < "${#_brewGnuUtils[@]}"; i++ )); do
    _gnuApp="${_brewGnuUtils[i]}"
    _brewGnuUtils[i]="$_brewGnuUtilsHomePrefix/$_gnuApp/$_brewGnuUtilsHomeSuffix"
done
BREW_GNU_UTILS_HOMES="`array.join _brewGnuUtils ':'`"

_brewPathEntries="$(echo "$BREW_PATHS" | sed -E 's/( |\t)+/:/g')" # /usr/local/sbin and some others

export PATH="$BREW_GNU_UTILS_HOMES:$PATH"

### Program paths ###
# Note: The `abspath` calls using glob-stars need to be unquoted so the glob is executed rather than
# interpreted as part of the filename/path.

export SUBLIME_HOME="/Applications/Sublime Text.app/Contents/SharedSupport/bin"
export SUBLIME_DIR="$HOME/Library/Application Support/Sublime Text/Packages/User"
export JAVA_HOME="$(abspath /Library/Java/JavaVirtualMachines/jdk*/Contents/Home)"
export ANDROID_ADB_CLI_HOME="$HOME/android-skd-cli-platform-tools"
# TeX root dir
export TEXROOT=/usr/local/texlive
# The main TeX directory
export TEXDIR="$(abspath $TEXROOT/2*)"
# Executables for TeX
export TEXBIN="$(abspath $TEXDIR/bin/*darwin*)"
# Directory for site-wide local files
export TEXMFLOCAL="$TEXROOT/texmf-local"
# Directory for variable and automatically generated data
export TEXMFSYSVAR="$TEXDIR/texmf-var"
# Directory for local config
export TEXMFSYSCONFIG="$TEXDIR/texmf-config"
# Personal directory for variable and automatically generated data
export TEXMFVAR="$(abspath $HOME/Library/texlive/2*/texmf-var 2>/dev/null)"  # Not always present on Mac
# Personal directory for local config
export TEXMFCONFIG="$(abspath $HOME/Library/texlive/2*/texmf-config 2>/dev/null)"  # Not always present on Mac
# Directory for user-specific files
export TEXMFHOME="$HOME/Library/texmf"
# Ruby
export PATH="/usr/local/opt/ruby/bin:$PATH"
export LDFLAGS="-L/usr/local/opt/ruby/lib ${LDFLAGS}"
export CPPFLAGS="-I/usr/local/opt/ruby/include ${CPPFLAGS}"
# OpenSSL
export PATH="/usr/local/opt/openssl@1.1/bin:$PATH"
export LDFLAGS="-L/usr/local/opt/openssl@1.1/lib ${LDFLAGS}"
export CPPFLAGS="-I/usr/local/opt/openssl@1.1/include ${CPPFLAGS}"

export PATH="$JAVA_HOME:$SUBLIME_HOME:$TEXBIN:$ANDROID_ADB_CLI_HOME:/usr/local/bin:$HOME/bin:$_brewPathEntries:$PATH"


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


alias devcurl="curl --noproxy '*'"


# Add --no-verify for git pushes since it takes forever and often dies half-way through
alias gp='git push --no-verify'
alias gpu='git push -u origin $(gitGetBranch) --no-verify'

alias todo="subl '~/Desktop/ToDo.md'"


if [[ "$MAC_ENV" != "$_MAC_ENV_PERSONAL" ]]; then
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
fi




cf() {
    touch "$1" && chmod a+x "$1"
}



alias getAllApps=`mdfind "kMDItemKind == 'Application'"`

getMacAppInfo() {
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

        if [[ -n "${property}" ]]; then
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

    if [[ -n "${appId}" ]]; then
        declare appPath="$(mdfind "kMDItemCFBundleIdentifier == $appId" | head -n 1)"

        if [[ -n "${appPath}" ]]; then
            if [[ -n "${property}" ]]; then
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

getMacAppBinaryPath() {
    getMacAppInfo "$1" 'binary'
}

getMacAppDomains() {
    declare _appNameOrDomainToSearch="${1:-\w}"

    defaults domains | egrep -io "\b[^ ]*${_appNameOrDomainToSearch}[^ ,]*\b"
}

getMacAppPath() {
    # Basically a simpler version of the `mdfind`/`osascript`
    #
    # See:
    #   - https://apple.stackexchange.com/questions/212445/the-location-of-plist-file-with-defaults
    #   - https://apple.stackexchange.com/questions/19899/how-to-list-all-available-plist-keys-on-a-certain-domain-application-by-default
    declare _appNameToSearch="${1:-\w}"

    mdfind -name '.app' | egrep -i '\.(plist|app)$' | egrep -i "$_appNameToSearch"
}


getMacSleepTime() {
    # " Sleep" = A sleep action initiated by the user rather than the computer
    # "lid" = A sleep action initiated by the user
    # "Assertions" = A sleep action initiated by the computerThe super short times the computer will wake from sleep to check for notifications
    pmset -g log \
        | grep -v Assertions \
        | egrep '( Sleep)|([lL]id)' \
        | {
            [[ "$1" =~ [0-9-] ]] \
                && date '+%m/%d/%Y %H:%M:%S' ${1:+--date="$1"} \
                || cat
        }
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



_disableDsstoreFileCreation() {
    if ! defaults read com.apple.desktopservices DSDontWriteNetworkStores | egrep -iq '(TRUE|1)'; then
        # Finder (file explorer) will create annoying `.DS_Store` files everywhere it visits,
        # which are akin to Windows' `desktop.ini` files.
        # All they do is tell Finder how to view the current directory (e.g. list-view, icon-view, etc.)
        # so they don't serve much purpose.
        # Thus, delete them and disable their creation.
        #
        # See:
        #   - https://www.techrepublic.com/article/how-to-disable-the-creation-of-dsstore-files-for-mac-users-folders/
        #   - https://support.apple.com/en-us/HT208209
        #   - `.plist` reloading: https://apple.stackexchange.com/questions/205596/reload-modified-system-plist
        #   - https://iboysoft.com/wiki/ds-store.html

        # Delete all current `.DS_Store` files (in HOME dir, ignore root dir for now)
        sudo find "$HOME" -iname '*\.DS_Store*' 2>/dev/null -delete &
        # Change OS settings to stop creating `.DS_Store` files
        defaults write com.apple.desktopservices DSDontWriteNetworkStores true
        # Reload all settings for Finder and related processes
        killall cfprefsd Finder finder
    fi
}
_disableDsstoreFileCreation



source "$_macSpecificProfile"
