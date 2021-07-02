# Useful special bash keywords: https://www.gnu.org/software/bash/manual/html_node/Bash-Variables.html

PATH="$HOME/bin:$PATH"
export PATH


### .bash_history improvements ###
# Variables below can be found in keywords link above.
# History commands: https://www.gnu.org/software/bash/manual/html_node/Bash-History-Builtins.html
###
# Remove duplicate commands.
HISTCONTROL=ignoredups:erasedups
# Increase number of commands to remember.
HISTSIZE=1000
# Increase number of lines to allow in the file - important for multiline commands.
HISTFILESIZE=$(( $HISTSIZE * 10 ))
# Append to .bash_history instead of overwriting it.
shopt -s histappend
# Option to allow history across all active shell sessions immediately rather than only on session close.
# Put in function so it can be (de-)activated in other .profile files.
ORIG_PROMPT_COMMAND="$PROMPT_COMMAND"
bashHistoryImmediatelyAvailableAcrossShellSessions() {
    # See:
    # https://unix.stackexchange.com/questions/1288/preserve-bash-history-in-multiple-terminal-windows
    # https://unix.stackexchange.com/questions/18212/bash-history-ignoredups-and-erasedups-setting-conflict-with-common-history
    local usage="(De-)activate .bash_history being written to immediately after running commands instead of only on shell termination.

    Usage: ${FUNCNAME[0]} [-a|-d]

    Options:
        -a | Activate immediate command appending.
        -d | Deactivate immediate command appending."

    local activate

    while getopts ":adh" opt; do
        case "$opt" in
            a)
                activate=true
                ;;
            d)
                activate=false
                ;;
            *)
                echo "$usage"
                return
                ;;
        esac
    done

    if [[ "$activate" = 'true' ]]; then
        # See: https://unix.stackexchange.com/questions/18212/bash-history-ignoredups-and-erasedups-setting-conflict-with-common-history/18443#18443
        # If this causes issues with history not being saved correctly, try: https://unix.stackexchange.com/questions/18212/bash-history-ignoredups-and-erasedups-setting-conflict-with-common-history/556267#556267
        PROMPT_COMMAND="history -n; history -w; history -c; history -r; $PROMPT_COMMAND"
    else
        PROMPT_COMMAND="$ORIG_PROMPT_COMMAND"
    fi
}


alias editprofile="subl -n -w ~/.profile && source ~/.profile"

alias ls='ls -Fh'
alias lah='ls -Flah'

alias grep='grep --exclude-dir={node_modules,.git,.idea,lcov-report} --color=auto'
alias egrep='grep -E --exclude-dir={node_modules,.git,.idea,lcov-report} --color=auto'
gril() {
    local query="$1"

    shift

    # Globs are expanded before being passed into scripts/functions. So if the user passed
    # a glob pattern as the second arg, then using `$2` only gets the first match, regardless
    # of whether or not it's nested inside strings (e.g. `path=$2` or `path="$2"`).
    #
    # Thus, expand it myself via "$@" (which gets all arguments passed to the function).
    # To ensure we only include files expanded from the glob, not the search query, store the
    # query first, then shift the arguments array by 1, then get all args remaining (which would be
    # the files matched by the glob pattern which was expanded before being passed to this script).
    local pathGlob="$@"

    if [ -z "$2" ]; then
        pathGlob=('.')
    fi

    egrep -ril "$query" $pathGlob
}

# -P (show full port numbers)
# -n (show full IPs)
# -i (show internet addresses, can be -i4/-i6 for IPv4/6, or -i:PORT for showing specific port)
alias listopenports='sudo lsof -Pn -i'

# `type` should be used instead; this is mostly meant as a reminder that it exists
alias define-func='type'


thisFile="$BASH_SOURCE"
thisDir="$(realpath "`dirname $thisFile`")"


reposDir="`realpath "$thisDir/.."`"
repos() {
    # Path is relative to repositories directory.
    # Read all args via `$@` instead of `$1` in case spaces aren't escaped.
    #   `"$@"` collects all args into one string, even those separated by spaces (which would usually
    #   be split into separate lines internally by bash/function arg interpretation).
    local nestedPath="$@"
    # Note: Manually parsing strings via something like
    # absPath="`echo "$reposDir/$nestedPath" | tr '\n' ' ' | sed -E 's:([^\\]) (.):\1\\ \2:g'`"
    # to (1) replace newline-separated args, and (2) replace the now-one-line `my path/` with `my\ path/`
    # doesn't work/help/add anything new because bash double-quote strings automatically remove
    # backslashes (spaces don't need escaping in strings).
    local absPath="$reposDir/$nestedPath"

    cd "$absPath"
}
_autocompleteRepos() {
    local requestedRelativePath="${COMP_WORDS[@]:1}"
    local requestedAbsPath="$reposDir/$requestedRelativePath"

    # Note: `sed` seems to handle backslashes differently depending on where and how it's used.
    #   If on root-level, these work:
    #     echo "$var" | sed -E 's:\\ : :g'
    #     echo "$var" | sed -E "s:\\\ : :g"
    #   If nested inside another call, these work:
    #     newVar="`echo "$var" | sed -E 's:\\\ : :g'`"   # note the triple \ even in single-quotes
    #     newVar="$(echo "$var" | sed -E "s:\\\ : :g")"  # note the similarity to root-level, but requires $() instead of back-ticks
    #     (haven't tested for the double-quote inside back-ticks)

    # `find` is stupid and won't resolve escaped paths.
    # But at the same time, the suggestion autocomplete system will fail if the path isn't escaped
    # (see COMPREPLY note below).
    # Thus, unescape them only for `find` but otherwise leave them untouched.
    requestedAbsPath="`echo "$requestedAbsPath" | sed -E 's:\\\ : :g'`"

    # `find` will also fail if `$requestedAbsPath` doesn't exist, e.g. when the user presses <Tab> on
    # a partial directory name.
    # Thus, if the dir doesn't exist, then default to searching in the parent dir.
    if [[ -d "$requestedAbsPath" ]]; then
        local resolvedRelativePath="$requestedRelativePath"
        local resolvedAbsPath="$requestedAbsPath"
    else
        local resolvedRelativePath="`dirname "$requestedRelativePath"`"
        local resolvedAbsPath="`dirname "$requestedAbsPath"`"
    fi

    local dirOptions="`find "$resolvedAbsPath" -maxdepth 1 -type d`"

    # Filter resulting directory options to include suggestions for only dirs that include the
    # string the user searched for.
    # Include partial dir names by using `$requestedAbsPath` instead of `$resolvedAbsPath`.
    # Note: Quote `$dirOptions` so that newlines are preserved.
    #   If it weren't quoted, all results would be on one line (`find` doesn't escape spaces in its
    #   results), causing any dirs that have spaces in their names to be impossible to parse separately.
    dirOptions="`echo "$dirOptions" | grep "$requestedAbsPath"`"

    # `sed "...d"` command is less user friendly than `s` in that to use any delimiter other
    # than `/`, it must be escaped.
    # e.g. `sed '/x/d'` --> `sed '\:x:d'`

    # Format dir options to be human readable.
    #   Remove the preceding repository-directory path.
    #   Remove any lines that are blank or only contain `/`.
    #   Replace double slashes with single slashes.
    #   Add a trailing slash to the end of dir options.
    dirOptions="`echo "$dirOptions" | sed -E "s:$reposDir/?::; \:^/?$:d; s://:/:; s:^/::; s:([^/])$:\1/:"`"

    if ! [[ -z "$requestedRelativePath" ]]; then
        # Remove the entry that is exactly the same as the path already prefilled in the shell
        dirOptions="`echo "$dirOptions" | egrep -v "$requestedRelativePath$"`"
    fi

    # Escape spaces in paths. See note above.
    dirOptions="$(echo "$dirOptions" | sed -E "s:([^\\]) (.):\1\\\ \2:g")"

    # Standard compgen logic, i.e.
    # `COMPREPLY=($(compgen -W "$dirOptions"))`
    # doesn't work when we manually escape strings because it takes the spaces out.
    # However, leaving unescaped spaces in causes the suggestions list to only autocomplete
    # the last word in the shell, resulting in a valid path's last word being replaced by
    # other random text (in our case, it's `find "$(dirname path)"` since we search the parent
    # if the child isn't found).
    # Thus, in order of causation:
    #   - The spaces have to be escaped
    #   - We can't use compgen
    #   - We generate our own word array
    #   - Word array needs to be split by newlines instead of spaces (done via IFS)
    # Note: Using quotes around paths was attempted, but that failed as well (also caused a worse
    # user experience b/c spaces being autocompleted in the shell wouldn't automatically be removed
    # when trying to go into a nested directory).
    local IFS=$'\n'
    COMPREPLY=($dirOptions)

    return 0
}
# Don't split options by space; split by newline instead b/c paths could include spaces in them.
# The easiest way to handle this would have been `-o filenames`, except that caused the issues above
# where the last word in a directory with spaces would be swapped out unexpectedly.
complete -F _autocompleteRepos -o nospace 'repos'


dirsize() {
    # ${FUNCNAME[0]} gets the name of this function, regardless of where it was called/defined
    usage="Displays total disk usages of all directories within the given path.

    Usage: ${FUNCNAME[0]} [-d=1] [-f] [path=./]

    Options:
        -d | Depth of directories to display; defaults to 1 (dirs inside <path>).
           | Total disk usages will be calculated regardless of -d value.
        -f | Include files in output."

    # local vars to avoid them being accessible outside this function
    local OPTIND=1 # bash is retarded and uses a *global* OPTIND, so it isn't reset on subsequent calls
    local depth=1
    local showFiles=false
    local path="."

    # "abc" == flags without an input following them, e.g. `-h` for --help
    # "a:"  == flags with an input following them, e.g. `-d 5`
    # ":ab" == leading colon activates silent mode, e.g. don't print `illegal option -- x`
    while getopts "d:fh" opt; do
        case "$opt" in # OPTARG is the variable containing the arg value
            d)
                depth="$OPTARG"
                ;;
            f)
                showFiles=true
                ;;
            *)
                # While nested functions are valid syntax in bash, we cannot create a
                # nested printUsage() function because it would be available outside the
                # scope of this function, and `local myFunc() {...}` is invalid syntax
                echo "$usage"
                return  # since this function is in a .profile, cannot use `exit` as that
                        # would exit the terminal session
                ;;
        esac
    done

    # ! (not) expression goes outside braces
    # -z is unary operator for length == 0
    # OPTIND gives the index of the next arg after getopts cycles through flags
    # Could instead do `shift "$((OPTIND - 1))"` to delete all args that getopts processed
    #   to allow for using $1 instead of ${!OPTIND}
    # ${x} == $x, gets arg at index `x`, e.g. $1
    # ${!x} is "indirection" - !x gets the value of x instead of its name, similar
    #   to JavaScript's `var x = 'hi'; return obj[x];` instead of `obj['x']`.
    if ! [[ -z "${!OPTIND}" ]]; then
        path="${!OPTIND}"
    fi

    if [ "$showFiles" = true ]; then
        echo -e "Directories:"
    fi

    # ls -lah has a max size display of 4.0K or 1G, so it doesn't show sizes bigger than that,
    # and doesn't tally up total size of nested directories.
    # du = disk usage
    #   -h human readable
    #   -d [--max-depth] of only this dir
    # sort -reverse -human-numeric-sort - sorts based on size number (taking into account
    #   human-readable sizes like KB, MB, GB, etc.) in descending order
    # Manually add '/' at the end of output to show they are directories
    du -h -d $depth "$path" | sort -rh | sed -E 's|(.)$|\1/|'

    if [ "$showFiles" = true ]; then
        # -e flag enables interpreting backslashes instead of printing them, e.g. \n
        echo -e "\nFiles:"

        # du can't mix -a (show files) and -d (depth) flags, so run it again for files
        find "$path" -maxdepth $depth -type f -print0 | xargs -0 du -h | sort -rh
    fi
}

memusage() {
    # `ps` = process status, gets information about a running process.
    # vsz = Virtual Memory Size: all memory the process can access, including shared memory and shared libraries.
    # rss = Resident Set Size: how much memory allocated to the process (both stack and heap), not including
    #       shared libraries, unless the process is actually using those libraries.
    # TL;DR, RSS is memory the process is using while VSZ is what the process could possibly use
    #
    # ps
    # | grep (column title line and search query)
    # | awk 'change columns 3 and higher to be in MB instead of KB'
    # | sed 'remove double-space from CPU column b/c not sure why it is there'
    ps x -eo pid,%cpu,user,command,vsz,rss | egrep -i "(RSS|$1)" | awk '{
        for (i=2; i<=NF; i++) {
            if ($i~/^[0-9]+$/) {
                $i=$i/1024 "MB";
            }
        }

        print
    }' | sed 's|  %CPU| %CPU|'
}

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

getAllCrlfFiles() {
    # find [args] -exec [command] "output from find" "necessary `-exec` terminator to show end of command"
    find . -not -type d -exec file "{}" ";" | grep CRLF
}

getAllLinesAfter() {
    # sed -rEgex '[start_line],[end_line]/pattern/ delete_lines_before_including_pattern_match'
    sed -E "1,/$1/ d"
}

getCommandsMatching() {
    # `compgen -c` lists all commands available to bash,
    # regardless of install location or binary vs function vs alias
    compgen -c | grep -E "$1"
}

##### Aliases and functions for git commands #####

openGitMergeConflictFilesWithSublime() {
    subl $(getGitBothModified)
}

ignoreFileInGitDiff() {
    git diff -- . ":!$1"
}

ignoreFileInGitDiffCached() {
    git diff --cached -- . ":!$1"
}

getGitBranch() {
    # get the current branch (one that starts with '* ')
    # replace '* ' with ''
    git branch | grep '*' | sed -E 's|(^\* )||'
}

getGitRepoName() {
    # get remote URL for 'origin'
    # | filter out '/repo-name.git' -o-onlyReturnMatch -m-getNmatches
    # | sed -rEgex substitute~(/|.git)~['']~globally (apply to all matches, not just 1)
    git remote -v | grep origin | egrep -o -m 1 "/[^/]+\.git" | sed -E 's~(/|.git)~~g'
}

getGitBothModified() {
    git status | grep both | sed 's|both modified:||'
}

getGitModifiedContaining() {
    git status | grep 'modified:' | sed 's|modified:||' | egrep -o '\S+' | grep "$1"
}

getGitDiffOfFilesContaining() {
    git diff $(getGitModifiedContaining "$1")
}

getGitIgnoredFiles() {
    git status --ignored
}

getGitParent() {
    # git doesn't track what a branch's parent is, so we have to guess from the git log output.
    # Hence, here we guess based off git log's default branch output first and output from merges second.
    # ref: https://github.community/t/is-there-a-way-to-find-the-parent-branch-from-which-branch-head-is-detached-for-detached-head/825
    local numLinesToShow=5

    if ! [ -z "$1" ]; then
        numLinesToShow=$1
    fi

    echo -e 'Possible parents (with respective commits for manual `git log`ing):\n'

    echo "Ancestor branches before $(getGitBranch):"
    # git log requires --decorate, otherwise the branch names are stripped from the output
    # when piped to other programs, like grep.
    # Find $numLinesToShow entries of commits that were on different branches within the git
    # log of only this branch's history.
    glb --decorate | egrep '\* commit [a-z0-9]+ \(' | head -n $numLinesToShow

    echo -e "\nMerges to $(getGitBranch)"
    # git log only this branch's history
    # filter to display only 5 lines before anything that was merged to this branch
    # get the commit hash of only the last entry (since this hash was the very first merge to the current branch)
    local commitsMergingToCurrentBranch=$(glb | grep -B 5 "to $(getGitBranch)" | grep "commit" | awk '{print $3}' | tail -1)
    # again, decorate git log, and print out only the latest few logs for the above first merge to the current branch,
    # in the hopes that one of those latest logs would be where the current branch was created out of
    git log --decorate $commitsMergingToCurrentBranch | egrep '^commit [a-z0-9]+ \(' | awk '{print "* "$0}' | head -n $numLinesToShow
}

getAllGitReposInDir() {
    local parentDir='.'
    local gitDirs=()

    if ! [ -z "$1" ]; then
        parentDir="$1"
    fi

    parentDir="$(cd "$parentDir" && pwd)"

    local parentDirContents=$parentDir/*

    for file in $parentDirContents; do
        if [ -d "$file" ]; then # -d = isDirectory
            if [ -d "$file/.git" ]; then # if $file directory contains .git/
                gitDirs+=("$file")
            fi
        fi
    done

    echo ${gitDirs[@]}
}

updateAllGitRepos() {
    usage="Updates all git repositories with 'git pull' at the given parent path.

    Usage: ${FUNCNAME[0]} [-s] [path=./]

    Options:
        -s | Run 'git status' after 'git pull'."

    # local vars to avoid them being accessible outside this function
    local OPTIND=1
    local getStatus=false

    while getopts "sh" opt; do
        case "$opt" in
            s)
                getStatus=true
                ;;
            *)
                echo "$usage"
                return
                ;;
        esac
    done

    shift "$((OPTIND - 1))"

    local gitDirs=$(getAllGitReposInDir $1)

    for dir in $gitDirs; do
        echo "Updating $dir..."
        (cd "$dir" && git pull && [ "$getStatus" = true ] && git status)
        echo -e "\n\n---------------------\n\n"
    done
}

gitGetStashNames() {
    local path='.'

    if ! [[ -z "$1" ]]; then
        path="$1"
    fi

    # TODO add way to get stash message
    echo "$(cd "$path" && git stash list | cut -d: -f1)"
}

gitExportStashes() {
    usage="Exports all git stashes to a single zip file.
    Usage: ${FUNCNAME[0]} [path=./]"

    local OPTIND=1

    while getopts ":h" opt; do
        case "$opt" in
            *)
                echo "$usage"
                return
                ;;
        esac
    done

    local path='.'

    if ! [[ -z "$1" ]]; then
        path="$1"
    fi

    local currDir="$(pwd)"
    local stashList=$(gitGetStashNames "$path")

    if [[ -z "$stashList" ]]; then
        echo "No stashes to export"
        return
    fi

    cd "$path"

    for stashName in $stashList; do
        # `--binary` flag shows the actual diff between two binary files
        # rather than only "Binary files X and Y differ", so it can be used to actually
        # save the diff for storage/usage on a different device.
        # See: https://git-scm.com/docs/git-diff/2.8.6#Documentation/git-diff.txt---binary
        git stash show -p --binary "$stashName" > "$stashName.patch"
        # Note: If you have a custom pager (e.g. so-fancy/diff-so-fancy or dandavison/delta)
        # then disabling the pager might help.
        # See: https://gist.github.com/alexeds/3641372#gistcomment-3236251
    done

    # TODO add option to create an entry for untracked files as well

    local stashPatchFileGlob='stash*.patch'
    local outputFileName='stashes.tar.gz'

    # `-` passes the output of the previous command to the piped command as input.
    # See: https://askubuntu.com/questions/1074067/what-does-the-syntax-of-pipe-and-ending-dash-mean/1074072#1074072
    #
    # It's like `xargs` except that `xargs` passes the piped fields as CLI arguments
    # whereas `-` passes it as input. For example:
    # `cat output.txt | myCommand -` is equivalent to `myCommand < output.txt`
    # but `cat output.txt | xargs myCommand` is equivalent to `myCommand output-line-1 output-line-2 ...`
    # See: https://askubuntu.com/questions/703397/what-does-the-in-bash-mean/703434#703434
    find . -maxdepth 1 -type f -name "$stashPatchFileGlob" | tar -czf $outputFileName -T -

    rm $stashPatchFileGlob

    local outputFilePath="$(pwd)/$outputFileName"

    cd "$currDir"

    # TODO add info on how to push them onto current stash list rather than applying them
    # Places to start:
    # https://stackoverflow.com/a/47186156/5771107
    # https://gist.github.com/senthilmurukang/29b55a0c0e8694c406991799153f3c43
    # https://stackoverflow.com/questions/26116899/generating-patch-file-from-an-old-stash
    # https://stackoverflow.com/questions/20586009/how-to-recover-from-git-stash-save-all/20589663#20589663
    # https://stackoverflow.com/questions/1105253/how-would-i-extract-a-single-file-or-changes-to-a-file-from-a-git-stash

    echo "Stashes zipped to '$outputFilePath'
    * View zipped contents via 'tar -tf $outputFileName'
    * Unzip via 'tar -xzf $outputFileName'
    * Apply via 'git apply stash@{i}.patch'"
}

alias     g='git'
alias    gs='git status'
alias   gsi='getGitIgnoredFiles'
alias    gd='git diff'
alias   gds='getGitDiffOfFilesContaining'
alias   gdc='git diff --cached'
alias   gdl='git diff -R'  # show line endings - CRLF or CR; any CR removed will be a red `^M` in green lines
alias   gdi='ignoreFileInGitDiff'
alias  gdci='ignoreFileInGitDiffCached'
alias    ga='git add'
alias   gap='git add -p'
alias    gc='git commit -m'
alias   gca='git commit --amend'
alias   gac='git commit -am'
alias    gb='git branch'
alias   gbb='getGitBranch'
alias   gbd='git branch -d $(git branch | grep -v "*")'
alias   gck='git checkout'
alias    gl='git log --stat --graph'
alias   gld='git log --stat --graph -p' # show diff in git log (i.e. detailed `git blame`). Choose single file with `gld -- <file>`
alias   glo='git log --stat --graph --oneline'
alias   gla='git log --stat --graph --oneline --all'
alias   glb='gl --first-parent $(getGitBranch)' # only show this branch's commits
alias    gp='git push'
alias   gpu='git push -u origin $(getGitBranch)'
alias    gr='git reset'
alias   grH='git reset HEAD'
alias   grh='git reset --hard'
alias  grhH='git reset --hard HEAD'
alias   gpl='git pull'
alias   gst='git stash'
alias  gstl='git stash list'
alias  gsta='git stash apply'
alias  gsts='git stash push -m'
alias  gstp='git stash push'
alias  gstd='git stash show -p'
alias  gcon='openGitMergeConflictFilesWithSublime'
alias   gau='git update-index --assume-unchanged'
alias  gnau='git update-index --no-assume-unchanged'
alias  gauf="git ls-files -v | grep '^[[:lower:]]' | awk '{print \$2}'" # awk: only print second column (space-delimited by default)
alias gaufo='subl $(gauf | cut -f 2 -d " ")'

alias  gcmd="cat '$thisFile' | egrep -i '(alias *g|^\w*Git\w*\(\))' | grep -v 'grep=' | sed -E 's/ \{$//'"

# To use bash autocompletion for multi-word commands,
# you'd need to add a wrapper function, e.g.
# _git_wrapper() {
#     gitCommand="$1"
#     shift
#     git $gitCommand $@
# }
# But aliases are easier since you don't alter the original function's autocompletion.
#
# Add bash autocompletion for `git checkout`
# Docs: https://www.gnu.org/software/bash/manual/html_node/Programmable-Completion-Builtins.html
# Example: https://tldp.org/LDP/abs/html/tabexpansion.html
_autocompleteWithAllGitBranches() {
    # COMP_WORDS is the current entire line in the live shell as an array.
    #   e.g. `my-cmd arg1 arg2` in the shell produces `COMP_WORDS=('my-cmd' 'arg1' 'arg2')`
    # COMP_CWORD is the index of the last entry in COMP_WORDS.
    #   e.g. `my-cmd arg1 arg2` in the shell produces `COMP_CWORD=2`
    #   Note: `my-cmd ` also produces `COMP_CWORD=2`, with `COMP_WORDS=('my-cmd' '')`
    # COMPREPLY is an array of suitable words with which to autocomplete.

    # Get the latest word in the live shell.
    # Will update to the only matching autocomplete prefix/word when <Tab> is pressed.
    #   e.g. `git reba` will automatically prefill `git rebase` into the live shell
    #   if it's the only suggestion.
    local lastArg="${COMP_WORDS[COMP_CWORD]}"

    # Don't suggest branches if first arg has already been autocompleted.
    # Leave all args past that to the default shell autocomplete via `complete -o default`.
    if [[ $COMP_CWORD -gt 1 ]]; then
        return 0
    fi

    # Autocomplete `gck -` and `gck --` to `gck -- ` for automatic space injection and quicker typing.
    if [[ "$lastArg" = "-" ]] || [[ "$lastArg" = "--" ]]; then
        COMPREPLY=($(compgen -W '--'))

        return 0
    fi

    local showRemoteBranches=yes # comment out to disable
    local cmdOption

    [[ $showRemoteBranches ]] && cmdOption='-r' || cmdOption=''

    local gitBranches="`git branch $cmdOption`"

    # Maintain newlines by quoting `$gitBranches` so they're easier to read/modify.
    # Filter out HEAD since it just points to a branch that is defined later in the list.
    # Remove out leading */spaces from output.
    # Remove remote name from branch names.
    gitBranches="`echo "$gitBranches" | grep -v 'HEAD' | sed -E 's$^(\*| )*$$; s$^[^/]*/$$'`"

    # Filter out non-matching branch names.
    # Theoretically, we'd have to replace \n with ' ' so the autocomplete suggestions
    # wouldn't include them, but luckily, the internal system does that automatically
    # ASSUMING, of course, that we don't have spaces in the names. If we did, we'd
    # have to change `IFS=$'\n'`.
    # One nice way to replace newlines with spaces would be with `tr '\n' ' '`
    # because `sed` only works one line at a time, so it can't parse '\n'.
    gitBranches="`echo "$gitBranches" | egrep "^$lastArg"`"

    COMPREPLY=($(compgen -W "$gitBranches"))

    return 0
}
# Activate function `_autocompleteWithAllGitBranches` for bash shell entry `gck`.
# If we're done with suggestions, default to whatever bash would auto-suggest
# via `-o default`.
complete -F _autocompleteWithAllGitBranches -o default "gck"
