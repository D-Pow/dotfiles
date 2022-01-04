openGitMergeConflictFilesWithSublime() {
    subl -n $(gitGetBothModified)
}


ignorePathsInGit() {
    # Git offers a glossary of terms to modify how commands work,
    # e.g. only showing some files, excluding others, etc.
    # Kind of like `git diff -- src/dir/` except supporting more
    # complex queries.
    # Docs: https://git-scm.com/docs/gitglossary
    #
    # For ignoring files:
    #   `:(top)` = git root (shorthand: `.` but only if in root dir)
    #   `:(exclude)myPath` = path to exclude (shorthand: `:!myPath`)
    # Ref: https://stackoverflow.com/a/39937070/5771107
    declare _gitIgnoreArgs=("$@")
    declare _gitIgnorePaths
    array.map -r _gitIgnorePaths _gitIgnoreArgs "echo \"':(exclude)\$value'\""

    if [[ -z "$_gitIgnorePaths" ]] || array.empty _gitIgnorePaths; then
        return
    fi

    # TODO Will likely require `eval $cmd -- <text below>` because
    # it doesn't currently work with ANY combination of quotes above, below,
    # in between, or a removal of `-r retArray` in the above `array.map` call.
    # TODO `:(top)` doesn't work
    echo "':(top)'" ${_gitIgnorePaths[@]}
}


ignoreFileInGitDiff() {
    git diff -- . ":!$1"
}


ignoreFileInGitDiffCached() {
    git diff --cached -- . ":!$1"
}


gitGetBranch() {
    # get the current branch (one that starts with '* ')
    # replace '* ' with ''
    # Alternative: git rev-parse --abbrev-ref HEAD
    git branch | grep '*' | sed -E 's|(^\* )||'
}


gitGetRepoName() {
    # get remote URL for 'origin'
    # | filter out '/repo-name.git' -o-onlyReturnMatch -m-getNmatches
    # | sed -rEgex substitute~(/|.git)~['']~globally (apply to all matches, not just 1)
    git remote -v | grep origin | egrep -o -m 1 "/[^/]+\.git" | sed -E 's~(/|.git)~~g'
}


gitGetBothModified() {
    git status | grep both | sed -E 's|.*modified:||; s|^\s*||'
}


gitGetModifiedContaining() {
    declare _gitModifiedFilesPrefixes=(
        'modified'
    )
    declare _includeNewFiles
    declare argsArray
    declare -A optionConfig=(
        ['n|new,_includeNewFiles']='Include new files in output'
        ['USAGE']='Get all modified files tracked by git.'
    )

    parseArgs optionConfig "$@"
    (( $? )) && return 1

    if [[ -n "$_includeNewFiles" ]]; then
        _gitModifiedFilesPrefixes+=('file')
    fi

    # All prefixes end with a colon
    declare _gitModifiedFilesPrefix="($(array.join -s _gitModifiedFilesPrefixes '|')):"
    declare _gitModifiedSearchQuery="${argsArray[@]}"

    git status | egrep "$_gitModifiedFilesPrefix" | sed -E 's|.*:||; s|^\s*||' | egrep --color=never "$_gitModifiedSearchQuery"
}


gitGetDiffOfFilesContaining() {
    git diff $(gitGetModifiedContaining "$1")
}


gitGetIgnoredFiles() {
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

    # http://git-scm.com/docs/git-rev-parse
    # `basename` gets the last entry after all slashes in a path (as opposed to `dirname` which gets everything before the last slash)
    basename $(git rev-parse --symbolic-full-name "refs/remotes/$_gitPrimaryBranchRemoteName/HEAD")

    # Old way: Works fast with repositories with few branches, but slows down to >= 1 second with many branches
    # git remote show "$_gitPrimaryBranchRemoteName" | grep HEAD | sed -E 's/.*branch: (.*)/\1/'
}


gitGetFilesChangedFromRebase() {
    # Allow only showing certain files in diff output
    local _diffFileFilter="${1:-.}"

    # `git diff --stat` only shows "filename  |  numLines +-" rather than full file diffs
    # Thus, strip out the trailing numLines (note: don't blindly use `(\S+)` b/c file renames use spaces, e.g. "old => new")
    local _diffOnlyFileSedRegex='s/^\s*([^|]*)\|.*/\1/; s|\s+$||'
    local _diffFromPrimaryToHead="$(git diff --stat origin/$(gitGetPrimaryBranch)..HEAD | egrep "$_diffFileFilter" | esed "$_diffOnlyFileSedRegex")"
    local _diffFromRemoteToHead="$(git diff --stat origin/$(gitGetBranch)..HEAD | egrep "$_diffFileFilter" | esed "$_diffOnlyFileSedRegex")"

    echo -e "$_diffFromPrimaryToHead\n$_diffFromRemoteToHead" | sort | uniq -d
}


gitGetLastCommitHash() {
    # https://git-scm.com/docs/git-show#_pretty_formats
    git show -s --format='%h'
}


gitGetParent() {
    # git doesn't track what a branch's parent is, so we have to guess from the git log output.
    # Hence, here we guess based off git log's default branch output first and output from merges second.
    # ref: https://github.community/t/is-there-a-way-to-find-the-parent-branch-from-which-branch-head-is-detached-for-detached-head/825
    local numLinesToShow=5

    if ! [ -z "$1" ]; then
        numLinesToShow=$1
    fi

    echo -e 'Possible parents (with respective commits for manual `git log`ing):\n'

    echo "Ancestor branches before $(gitGetBranch):"
    # git log requires --decorate, otherwise the branch names are stripped from the output
    # when piped to other programs, like grep.
    # Find $numLinesToShow entries of commits that were on different branches within the git
    # log of only this branch's history.
    glb --decorate | egrep '\* commit [a-z0-9]+ \(' | head -n $numLinesToShow

    echo -e "\nMerges to $(gitGetBranch)"
    # git log only this branch's history
    # filter to display only 5 lines before anything that was merged to this branch
    # get the commit hash of only the last entry (since this hash was the very first merge to the current branch)
    local commitsMergingToCurrentBranch=$(glb | grep -B 5 "to $(gitGetBranch)" | grep "commit" | awk '{print $3}' | tail -1)
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


gitConfigWithScopes() {
    # Show `git config` entries' scopes, files, and contents, except pretty-print
    # them so that all configs under the same scope/file are nested together.
    #
    # Requires `awk` because otherwise we can't easily inject newlines between different
    # config scopes (e.g. `sed` doesn't work across multiple lines).
    #
    # Note: `awk` can't accept (associative) arrays from Bash, so they must be created within `awk` itself.
    # See: https://stackoverflow.com/questions/33105808/can-i-pass-an-array-to-awk-using-v
    # But, `awk` can be used to create Bash arrays.
    # See: https://stackoverflow.com/questions/48139210/awk-store-a-pattern-result-to-a-shell-array-variable

    if [[ $1 == "-h" ]] || [[ $1 == "--help" ]]; then
        echo 'Runs `git config --show-scope --show-origin "$@"` except co-locating all scope config entries together under one heading instead of on every single line.'
        return 1
    fi

    # Scope = local/global/system/etc.
    # Origin = file path.
    #
    # Awk docs: https://www.gnu.org/software/gawk/manual/gawk.html
    # Git-config docs: https://git-scm.com/docs/git-config#FILES
    #
    # Newline insertion inspired by: https://bytefreaks.net/gnulinux/bash/add-a-new-line-whenever-the-first-column-changes
    # Inserting white-space between `awk` `print` entries: https://askubuntu.com/questions/231995/how-to-separate-fields-with-space-or-tab-in-awk/231998#231998
    git config --show-scope --show-origin "$@" | awk '
        {
            prevScope = scope   # Save previous git scope
            scope = $1      # Current scope is first column
            file = $2       # File is second column
            $1 = ""         # Erase scope and file from output so we can print from $3 and onward
            $2 = ""         # See: https://stackoverflow.com/questions/2961635/using-awk-to-print-all-columns-from-the-nth-to-the-last/2961994#2961994
            output = $0     # Actual config entry (regardless of whether or not spaces exist)

            # Arrays (e.g. `scopeFileMap`) do not need initialization

            # ! is not a valid if-statement operator, so use empty if-statement for `if (!condition)`
            # See: https://stackoverflow.com/questions/10923812/why-does-awk-not-in-array-work-just-like-awk-in-array

            if (scope in scopeFileMap); else {
                # If git config `scope` is not in scope-file map, then add it.
                #
                # Replace `file:path` with `(file: path)`
                # `gensub(regex, replacement, mode, variableOrString)`
                # See: https://www.gnu.org/software/gawk/manual/gawk.html#String-Functions
                # Example: https://unix.stackexchange.com/questions/25122/how-to-use-regex-with-awk-for-string-replacement/25123#25123

                scopeFileMap[scope] = "(" gensub(/(file:)(.*)/, "\\1 \"\\2\"", "g", file) ")"
            }

            if (scope != prevScope) {
                # Add new scope/filePath header for new category of config entries

                if (NR > 1) {
                    # Only print newline if not first output line
                    print ""
                }

                # Same as below, but shows another way to print what you want
                #   print scope " " scopeFileMap[scope]
                printf ("%s %s\n", scope, scopeFileMap[scope])
            }

            prevScope = scope

            print output
        }
    '
}


gitUpdateRepos() {
    usage="Updates all git repositories with 'git pull' at the given parent path.

    Usage: ${FUNCNAME[0]} [-s] [paths=./]

    Options:
        -s | Run 'git status' after 'git pull'."

    # local vars to avoid them being accessible outside this function
    local getStatus=false
    local OPTIND=1

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


gitStashDiffPaths() {
    # Uses `git diff` to show the diff of a stash while allowing paths to be specified.
    # Since `git diff HEAD~n` shows the diff of _n_ commits before HEAD, and it allows paths to be specified
    # with `--`, we can use this to show the diff of a stash for specific files.
    #
    # Note that the parent commit of a stash is the commit made right before the stash was created, which
    # means the diff between `stash@{n}~` and `stash@{n}` is only the stash's content.
    #
    # Ref: https://stackoverflow.com/questions/1105253/how-would-i-extract-a-single-file-or-changes-to-a-file-from-a-git-stash/1105666#1105666
    declare USAGE="${FUNCNAME[0]} <stashId> <...paths>
    Displays the diff of a git stash for the specified path(s).
    Useful to see what the stash contains while focusing only on the files you care to see without the extra noise for the others.
"

    if [[ "$1" == "-h" ]] || [[ "$1" == "--help" ]]; then
        echo -e "$USAGE"
        return 1
    fi

    declare stashIdToDiff="${1:-0}"

    shift

    git diff "stash@{$stashIdToDiff}^1" "stash@{$stashIdToDiff}" -- "${@:-.}"
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

    declare OPTIND=1

    while getopts ":h" opt; do
        case "$opt" in
            *)
                echo "$usage"
                return
                ;;
        esac
    done

    declare path='.'

    if [[ -n "$1" ]]; then
        path="$1"
    fi

    declare currDir="$(pwd)"
    declare stashList=$(gitGetStashNames "$path")

    if [[ -z "$stashList" ]]; then
        echo "No stashes to export"
        return
    fi

    cd "$path"

    for stashName in $stashList; do
        # `--binary` flag shows the actual diff between two binary files
        # rather than only "Binary files X and Y differ", so it can be used to
        # save their diffs for later restoration.
        # See: https://git-scm.com/docs/git-diff/2.8.6#Documentation/git-diff.txt---binary
        #
        # Note:
        # * If using a custom pager (e.g. `so-fancy/diff-so-fancy` or `dandavison/delta`),
        #   then it needs to be disabled with `--no-pager`.
        #   See: https://gist.github.com/alexeds/3641372#gistcomment-3236251
        # * While not usually the case, there is a chance color information could be written to
        #   the file as well (like how `jest` output includes color info), so it needs to
        #   be disabled as well with `--no-color`.
        #   See: (comment above the one linked above about the custom pager)
        git --no-pager stash show --no-color -p --binary "$stashName" > "$stashName.patch"
    done

    # TODO add option to create an entry for untracked files as well

    declare stashPatchFileGlob='stash*.patch'
    declare outputFileName='stashes.tar.gz'
    declare outputStashMessagesFileName='stash-messages.log'

    git stash list > "$outputStashMessagesFileName"

    # `-` passes the output of the previous command to the piped command as input.
    # See: https://askubuntu.com/questions/1074067/what-does-the-syntax-of-pipe-and-ending-dash-mean/1074072#1074072
    #
    # It's like `xargs` except that `xargs` passes the piped fields as CLI arguments
    # whereas `-` passes it to stdin. For example:
    # `cat output.txt | myCommand -` is equivalent to `myCommand < output.txt`
    # but `cat output.txt | xargs myCommand` is equivalent to `myCommand output-line-1 output-line-2 ...`
    # See: https://askubuntu.com/questions/703397/what-does-the-in-bash-mean/703434#703434
    #
    # `tar -T` gets names to be added/extracted in the same way CLI args are parsed:
    #   with quote removal, word splitting, and treating everything beginning with `-` option flags
    find . -maxdepth 1 -type f \
        \( -name "$stashPatchFileGlob" \) \
        -o \
        \( -name "$outputStashMessagesFileName" \) \
        | tar -czf $outputFileName -T -

    rm $stashPatchFileGlob "$outputStashMessagesFileName"

    declare outputFilePath="$(pwd)/$outputFileName"

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


gitLogIgnoreFileRenames() {
    # Allows `git log --follow` to work if no file/path provided.
    # `--stat` = Show changed files and their respective number of lines added/removed.
    # `--graph` = Show ASCII art for branch relationships (merges, base branches, etc.).
    # `--follow` = Follow file history beyond renames instead of stopping at them (removing noisy "-100 lines here, +100 lines there" in the process).
    #   Requires only one file (or path without globs) to be specified.
    #   But, that file/path doesn't have to be *right after* `--follow` and/or could be after `--` e.g. `git log -- path/file.txt`
    #       so we can use that to auto-inject `.` if `git log --follow` fails.
    declare _gitLogCmd="git log --stat --graph --follow"

    # `-n <number>` = max number of commits to display.
    # Use to make `git log` command check quick (i.e. don't actually try to load up the entire git history).
    #
    # Allows us to check whether or not the command works, e.g.
    #   `git log --follow [-n 0]`  =>  Error, requires exactly one path-spec (thus, add `.`)
    #   `git log --follow [-n 0] file.txt`  =>  (Success! Has no output)
    if eval "$_gitLogCmd -n 0 $@" &>/dev/null; then
        eval "$_gitLogCmd $@"
    else
        eval "$_gitLogCmd $@ ."
    fi
}


gitRebaseNCommitsBeforeHead() {
    git rebase -i "HEAD~$1"
}


gitChangeEmail() {
    declare USAGE="${FUNCNAME[0]} [-f|--force] [newEmail = '\`git config user.name\`@users.noreply.github.com']
    Rewrites all local branches' author/committer emails to use the new email.
    Preserves commit date, messages, and all other info except the commit hash.
    \`-f\` forces overwriting previous
"

    if [[ "$1" =~ ^-h|--help$ ]]; then
        echo -e "$USAGE"
        return 1
    fi

    declare _gitNewEmailForce=

    if [[ "$1" =~ ^-f|--force$ ]]; then
        _gitNewEmailForce=true
        shift
    fi

    declare _gitNewEmail="$1"

    if [[ -z "$_gitNewEmail" ]]; then
        _gitNewEmail="$(git config user.name)@users.noreply.github.com"
    fi

    echo "Changing git author/committer emails to: $_gitNewEmail"
    echo

    # Refs:
    #   Changing custom git fields, leaving the rest intact:
    #       Answer:
    #           https://stackoverflow.com/questions/41301627/how-to-update-git-commit-author-but-keep-original-date-when-amending/41303384#41303384
    #       Alternative:
    #           https://stackoverflow.com/questions/750172/how-to-change-the-author-and-committer-name-and-e-mail-of-multiple-commits-in-gi
    #       Rebase without changing date:
    #           https://stackoverflow.com/questions/2973996/git-rebase-without-changing-commit-timestamps
    #       Rebase timestamp flag descriptions:
    #           https://stackoverflow.com/questions/1579643/change-timestamps-while-rebasing-git-branch/63751470#63751470
    #   Git docs
    #       FilterBranch: https://git-scm.com/docs/git-filter-branch
    #           Keywords available: https://git-scm.com/docs/git-commit-tree
    #       Rebase: https://git-scm.com/docs/git-rebase
    #       Format: https://git-scm.com/docs/pretty-formats
    #
    # `--env-filter` takes a string of commands in Bash syntax and exports anything you want to change.
    # `--branches/tags` rewrites info on all branches/tags present locally (NOT on remote).
    git filter-branch ${_gitNewEmailForce:+-f} --env-filter "
    if [[ \"\$GIT_COMMITTER_EMAIL\" != \"$_gitNewEmail\" ]] || [[ \"\$GIT_AUTHOR_EMAIL\" != \"$_gitNewEmail\" ]]; then
        export GIT_COMMITTER_EMAIL='$_gitNewEmail'
        export GIT_AUTHOR_EMAIL='$_gitNewEmail'
    fi
    " --tag-name-filter cat -- --branches --tags

    echo 'Done!'

    echo "Verify with commands like:
    * git diff \"origin/$(gitGetBranch)..HEAD\"
    * Re-clone repo elsewhere and diff git logs via:
        git log --stat --graph > new.log
        diff old.log new.log | egrep -v '(commit)|(Author)|(---)|([0-9]+,[a-zA-Z0-9]+,[0-9]+)'
"
}


alias     g='git'
alias    gs='git status'
alias   gsi='gitGetIgnoredFiles'
alias    gd='git diff'
alias   gds='gitGetDiffOfFilesContaining'
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
alias   gbb='gitGetBranch'
alias   gbd='git branch -d $(git branch | grep -v "*")'
alias   gck='git checkout'
alias    gl='gitLogIgnoreFileRenames'
alias   gld='gl -p' # show diff in git log (i.e. detailed `git blame`). Choose single file with `gld -- <file>`
alias   glo='gl --oneline'
alias   gla='gl --oneline --all'
alias   glb='gl --first-parent $(gitGetBranch)' # only show this branch's commits
alias   gls='gl --grep'
alias  glsd='gld --grep'
alias    gp='git push'
alias   gpu='git push -u origin $(gitGetBranch)'
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
alias gstdf='gitStashDiffPaths'
alias  grbs='git rebase'
alias grbsi='gitRebaseNCommitsBeforeHead'
alias grbsc='git rebase --continue'
alias grbsa='git rebase --abort'
alias  gcon='openGitMergeConflictFilesWithSublime'
alias   gau='git update-index --assume-unchanged'
alias  gnau='git update-index --no-assume-unchanged'
alias  gauf="git ls-files -v | grep '^[[:lower:]]' | awk '{print \$2}'" # awk: only print second column (space-delimited by default)
alias gaufo='subl $(gauf | cut -f 2 -d " ")'
alias   gsb='git submodule'
alias  gsbd='gd --submodule=diff'

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
        return
    fi

    # Autocomplete `gck -` and `gck --` to `gck -- ` for automatic space injection and quicker typing.
    if [[ "$lastArg" = "-" ]] || [[ "$lastArg" = "--" ]]; then
        COMPREPLY=($(compgen -W '--'))

        return
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

    return
}
# Activate function `_autocompleteWithAllGitBranches` for bash shell entry `gck`.
# If we're done with suggestions, default to whatever bash would auto-suggest
# via `-o default`.
complete -F _autocompleteWithAllGitBranches -o default "gck"
