PATH="$HOME/bin:$PATH"
export PATH

alias editprofile="subl -n -w ~/.profile && source ~/.profile"

alias ls='ls -Fh'
alias lah='ls -Flah'

alias grep='grep --exclude-dir={node_modules,.git,.idea,lcov-report} --color=auto'
alias egrep='egrep --exclude-dir={node_modules,.git,.idea,lcov-report} --color=auto'
gril() {
    grep "$1" -ril .
}

dirsize() {
    usage="Displays total disk usages of all directories within the given path.

    Usage: dirsize [-d=1] [-f] [path=./]

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
alias npmf="npm run test 2>&1 | egrep -o '^FAIL.*'" # only print filenames of suites that failed

getAllCrlfFiles() {
    # find [args] -exec [command] "output from find" "necessary `-exec` terminator to show end of command"
    find . -not -type d -exec file "{}" ";" | grep CRLF
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
    local numLinesToShow=5

    if ! [ -z "$1" ]; then
        numLinesToShow=$1
    fi

    echo 'Possible parents (with respective commits for manual `git log`ing):'

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
alias  gsts='git stash save'
alias  gstp='git stash push'
alias  gstd='git stash drop'
alias  gcon='openGitMergeConflictFilesWithSublime'
alias   gau='git update-index --assume-unchanged'
alias  gnau='git update-index --no-assume-unchanged'
alias  gauf="git ls-files -v | grep '^[[:lower:]]' | awk '{print \$2}'" # awk: only print second column (space-delimited by default)
alias gaufo='subl $(gauf | cut -f 2 -d " ")'
alias  gcmd="cat ~/.profile | grep -e 'alias *g' | grep -v 'grep='"
