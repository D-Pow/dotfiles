openGitMergeConflictFilesWithSublime() {
    subl -n $(getGitBothModified)
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
    git status | grep both | sed -E 's|.*modified:||; s|^\s*||'
}


getGitModifiedContaining() {
    git status | grep 'modified:' | sed -E 's|modified:||; s|^\s*||' | egrep "$1"
}


getGitDiffOfFilesContaining() {
    git diff $(getGitModifiedContaining "$1")
}


getGitIgnoredFiles() {
    git status --ignored
}


gitBlameParentOfCommit() {
    local _gitBlameParentOfCommitUsage="Gets the git blame of a parent commit and previous file name/path.
    Very useful for when files were renamed or bulk syntax formatting was done, hiding the blame you're looking for.

    Usage:
        ${FUNCNAME[0]} <commit-hash> <file(s)>

    Executes:
        git blame 'af87d2^' -- file.txt
    "

    if [[ -z "$1" ]] || [[ -z "$2" ]]; then
        echo "$_gitBlameParentOfCommitUsage" >&2
        return 1
    fi

    git blame "$1^" "${@:2}"
}


gitGetPrimaryBranch() {
    local _gitPrimaryBranchRemoteName="${1:-origin}"

    git remote show "$_gitPrimaryBranchRemoteName" | grep HEAD | esed 's|.*\s(\S*)$|\1|'
}


gitGetFilesChangedFromRebase() {
    # Allow only showing certain files in diff output
    local _diffFileFilter="${1:-.}"

    # `git diff --stat` only shows "filename  |  numLines +-" rather than full file diffs
    # Thus, strip out the trailing numLines (note: don't blindly use `(\S+)` b/c file renames use spaces, e.g. "old => new")
    local _diffOnlyFileSedRegex='s/^\s*([^|]*)\|.*/\1/; s|\s+$||'
    local _diffFromPrimaryToHead="$(git diff --stat origin/$(gitGetPrimaryBranch)..HEAD | egrep "$_diffFileFilter" | esed "$_diffOnlyFileSedRegex")"
    local _diffFromRemoteToHead="$(git diff --stat origin/$(getGitBranch)..HEAD | egrep "$_diffFileFilter" | esed "$_diffOnlyFileSedRegex")"

    echo -e "$_diffFromPrimaryToHead\n$_diffFromRemoteToHead" | sort | uniq -d
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


gitGetReposInDir() {
    local parentDir='.'
    local gitDirs=()

    if ! [ -z "$1" ]; then
        parentDir="$1"
    fi

    parentDir="$(cd "$parentDir" && pwd)"

    local parentDirContents=$parentDir/*
    local file=

    for file in $parentDirContents; do
        if [ -d "$file" ]; then # -d = isDirectory
            if [ -d "$file/.git" ]; then # if $file directory contains .git/
                gitDirs+=("$file")
            fi
        fi
    done

    if [ -d "$parentDir/.git" ]; then # if $parentDir itself contains .git/
        gitDirs+=("$parentDir")
    fi

    echo ${gitDirs[@]}
}


gitUpdateRepos() {
    usage="Updates all git repositories with 'git pull' at the given parent path.

    Usage: ${FUNCNAME[0]} [-s] [paths=./]

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

    local pathsToSearch=('.')
    local gitDirs=()

    if [[ -n "$@" ]]; then
        pathsToSearch=("$@")
    fi

    local dir=

    for dir in ${pathsToSearch[@]}; do
        gitDirs+=($(gitGetReposInDir "$dir"))
    done

    for dir in "${gitDirs[@]}"; do
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
    local outputStashMessagesFileName='stash-messages.log'

    git stash list > "$outputStashMessagesFileName"

    # `-` passes the output of the previous command to the piped command as input.
    # See: https://askubuntu.com/questions/1074067/what-does-the-syntax-of-pipe-and-ending-dash-mean/1074072#1074072
    #
    # It's like `xargs` except that `xargs` passes the piped fields as CLI arguments
    # whereas `-` passes it as input. For example:
    # `cat output.txt | myCommand -` is equivalent to `myCommand < output.txt`
    # but `cat output.txt | xargs myCommand` is equivalent to `myCommand output-line-1 output-line-2 ...`
    # See: https://askubuntu.com/questions/703397/what-does-the-in-bash-mean/703434#703434
    find . -maxdepth 1 -type f \( -name "$stashPatchFileGlob" \) -o \( -name "$outputStashMessagesFileName" \) | tar -czf $outputFileName -T -

    rm $stashPatchFileGlob "$outputStashMessagesFileName"

    local outputFilePath="$(pwd)/$outputFileName"

    cd "$currDir"

    # TODO add info on how to push them onto current stash list rather than applying them
    # Places to start:
    # https://stackoverflow.com/a/47186156/5771107
    # https://gist.github.com/senthilmurukang/29b55a0c0e8694c406991799153f3c43
    # https://stackoverflow.com/questions/26116899/generating-patch-file-from-an-old-stash
    # https://stackoverflow.com/questions/20586009/how-to-recover-from-git-stash-save-all/20589663#20589663
    # https://stackoverflow.com/questions/1105253/how-would-i-extract-a-single-file-or-changes-to-a-file-from-a-git-stash

    echo "Stashes zipped to '$outputFilePath' along with stash messages.
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
alias    gl='git log --stat --graph --follow' # STAT = show changed files w/ num lines added/removed. GRAPH = show ASCII art for branch relationships. FOLLOW = follow file history beyond renames instead of stopping at them (also removes noisy "-100 lines here, +100 lines there").
alias   gld='gl -p' # show diff in git log (i.e. detailed `git blame`). Choose single file with `gld -- <file>`
alias   glo='gl --oneline'
alias   gla='gl --oneline --all'
alias   glb='gl --first-parent $(getGitBranch)' # only show this branch's commits
alias   gls='gl --grep'
alias  glsd='gld --grep'
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

alias  gcmd="cat '$(thisFile)' | egrep -i '(alias *g|^\w*Git\w*\(\))' | grep -v 'grep=' | sed -E 's/ \{$//'"



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

    local gitBranches="$(git branch -a)"

    # Maintain newlines by quoting `$gitBranches` so they're easier to read/modify.
    # Filter out HEAD since it just points to a branch that is defined later in the list.
    # Remove out leading */spaces from output.
    # Remove remote name from branch names.
    gitBranches="`echo "$gitBranches" | grep -v 'HEAD' | sed -E 's~^(\*| )*~~; s~^(remotes(/origin)?)*/~~'`"

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
