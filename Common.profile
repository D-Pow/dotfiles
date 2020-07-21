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
    # Prints out size of all folders and files of current directory
    # ls -lah has a max-size display of 4.0K or 1G, so doesn't show dirs bigger than that
    # du = disk usage
    #   -h human readable
    #   -d [--max-depth] of only this dir
    # sort -reverse -human-readable - sorts based on size number in descending order
    du -h -d 1 ./ | sort -rh
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
alias  gauf="git ls-files -v | grep '^[[:lower:]]'"
alias  gaud='git update-index --assume-unchanged src/data/mocks/DefaultPageConfig.js'
alias gnaud='git update-index --no-assume-unchanged src/data/mocks/DefaultPageConfig.js'
alias  gcmd="cat ~/.profile | grep -e 'alias *g' | grep -v 'grep='"
