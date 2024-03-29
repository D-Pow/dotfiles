# Git Overview

Small overview of git as well as a summary of the most common and useful git commands.

More details can be found in the [git docs](https://git-scm.com/docs/) or `man`/`--help` pages.

## Contents

* [What is git?](#what-is-git)
* [Terms](#terms)
* [Common Commands](#common-commands)
    - [Base Commands](#base-commands)
    - [Advanced Commands](#advanced-commands)
    - [Util Commands](#util-commands)
* [Best Practices](#best-practices)
    - [Commits](#commits)
    - [Code Reviews](#code-reviews)
* [Shortcuts](#shortcuts)

## What is git?

A utility for tracking file changes, sharing those changes, and understanding when/why that change was made. It helps organize teams such that multiple people can work on the same set of files without being blocked by others or complicating the cooperation process when changing the same files.

In the world of software engineering, git helps us to organize code changes through explanations of each change, and grouping changes that introduce new features into separate branches.

## Terms

* **Commit** - A change to 1 or more files tracked in git; includes the associated message, hash, author, date, and other useful information.
    - **Message** - Short title for the commit. Could also include a longer *description* to give more context to the change.
    - **Hash** - A SHA-1 hash of the specific commit to identify it apart from other commits. **Note**: *every* commit has a different hash, including `cherry-pick` and `merge` commands.
    - e.g. `git log` shows the commit hash, HEAD branch pointers (if applicable), author, date, message, long message (if applicable), and changed files.
    ```
    * commit 96f935a1b27bebbd34d2c4965ad9885e0d31b146 (HEAD -> feature/MAS-3238, origin/feature/MAS-3238)
    | Author: dpowell1 <devon.powell@etrade.com>
    | Date:   Mon Jul 20 16:51:45 2020 -0400
    |
    |     MAS-3238 Bug fix: Make mock sessionStorage.getItem() return null if key not found
    |
    |     In JavaScript, attempting to get the value of an object that lacks the specified
          key returns `undefined`. However, sessionStorage.getItem(key) returns `null` instead.
          So, update the mock sessionStorage object used in testing to return `null` if the
          key isn't found instead of `undefined`.
    |
    |  testSetup.js | 2 +-
    |  1 file changed, 1 insertion(+), 1 deletion(-)
    |
    * commit c228dfe193cd1424923726dfc043e7f9f9f6cc3c
    | Author: dpowell1 <devon.powell@etrade.com>
    | Date:   Mon Jul 20 16:39:37 2020 -0400
    |
    |     MAS-3238 Add tests for new Store.getFrequencyMapping() function
    |
    |  tests/store/Store.test.js | 47 +++++++++++++++++++++++++++++++++++++++++++++++
    |  1 file changed, 47 insertions(+)
    ```
* **Stage** - Changes in files that are planned to be committed. Could be all or some changes in the working directory.
    - e.g. First section is staged (ready to be committed), second section is not
    ```
    On branch feature/MAS-4215-updateAipServicePortAndProtocol
    Changes to be committed:
      (use "git reset HEAD <file>..." to unstage)

        modified:   mutualFundEtf-services-webapp/src/main/resources/config/em.properties.template

    Changes not staged for commit:
      (use "git add <file>..." to update what will be committed)
      (use "git checkout -- <file>..." to discard changes in working directory)

        modified:   mutualFundEtf-aip-common/src/main/resources/config/serviceaccess/channel/AipChannelConfig.vm
        modified:   mutualFundEtf-services-webapp/src/main/resources/config/em.properties.template
    ```
* **Repository** - A directory that has been initialized with git and has a `.git/` directory in it.
    - **Remote** - A repository that exists in the cloud. This allows any authenticated user to clone, make changes/commits/branches, and push them back up for others to access.
    - **Local** - A repository that exists on your computer. Could be cloned from a remote repository or be local-only for tracking changes in your file system for your own, personal benefit.
* **Branch** - A collection of subsequent commits that are all related to a certain type of change (e.g. new feature addition, bug fix, etc.).
    - **HEAD** - A pointer in git to the latest commit on a branch.
        + It's possible for local/remote repository values for HEAD to differ, e.g. if you made changes locally but haven't run `git push`, yet.
        + You don't want to be in a *detached HEAD* state. Instead, use `git reset` (below).
* **origin** - The most common nickname for a remote repository. "origin" is automatically chosen when using `git (pull|fetch|push)` commands.
    - You can have multiple remote repositories associated with your local git repository, such as having one remote for holding source code (`origin`) and one remote for the deployment (`heroku`).
* **Pull-request** (a.k.a **PR**) - The process used in a remote repository to merge one branch into another branch while also showing the two branches' differences and allowing other users to comment on those differences.
    - Very useful feature of remote repositories because it allows your teammates to review your code before merging, and vice versa.
    - e.g. You will need to make a pull-request before merging your new feature/bug-fix branch to the main branch in the remote repository.
* **Merge conflict** - When the same line(s) in the same file(s) were modified in the source and destination branches of a pull-request or merge.
* **Index** - Git's internal tracking system, i.e. its way of determining if files are tracked, untracked, ignored, staged, etc.
* **Working directory** - Your local repository's state in between commits, i.e. the changes (staged and unstaged) you have made since the last commit.
* **.gitignore** - A file containing newline-separated glob entries that specifies files to ignore in the repository.
    - Common files to ignore include:
        + Build dirs (build/, dist/)
        + Test output (test-report.html, coverage/)
        + Dependency dirs (.gradle/, node_modules/)
        + IDE files (*.iml, .idea/)
        + OS-specific files (**/.DS_Store)

## Common Commands

* Generally speaking, a glob pattern can be added after most of the commands to apply them only to files/directories matching that glob.
    - Occasionally, you'll need to add two hyphens to allow glob patterns, e.g. `git checkout -- *.properties`.
    - This doesn't work with all commands (e.g. `git stash save` vs `git stash push`, explained below).
* `-v|--verbose` added after a command activates verbose mode.
* `-f|--force` added after a command forces the command to take place. Be cautious when using this.
* `--help` added after a command displays the manual page for the specified git command.

### Base Commands

* **`git init`** - Initializes a new repository in the current directory.
* **`git clone <url> <local-dir-name>`** - Clones a remote repository to your computer in a new directory specified by local-dir-name.
    - local-dir-name defaults to `./(remote-repo-name)`.
* **`git branch`** - Prelude to branch-related commands.
    - Defaults to listing all branches that have been checked out locally.
    - `<name>` - Creates (but doesn't checkout) a new branch at the current commit.
    - `-d <name>` - Deletes a local branch.
* **`git checkout`** - Checks out a branch. Alternatively, functions similarly to `git reset --hard` for specific files/paths.
    - `<branch-name>` - Checks out the branch with the given name.
    - `-b <new-branch-name>` - Combination of `git branch <new-branch-name>` and `git checkout <new-branch-name>`.
    - `-- <glob>` - Hard-resets the files/directories specified by the glob pattern.
* **`git status`** - Get an overview of your current git state.
    - Includes staged/unstaged/untracked files, current branch name, differences between current branch and respective remote branch, suggested next commands to run, and other details.
    - `--ignored` - Shows all ignored files, including files matching .gitignore patterns and those marked with `git update-index --assume-unchanged`.
    - IMO: It is surprisingly helpful to run `git status` (and occasionally `git diff --cached`) between every command to ensure everything looks as you expect, to see suggested next commands, and ensure local/remote branches haven't diverged or need merging before pushing.
* **`git diff`** - Like `git status`, but shows the changes in files line-by-line. Shows unstaged files by default.
    - `--cached` - Shows the diff for staged files.
* **`git add <globs...>`** - Adds any file matching the glob pattern(s) to the stage.
    - `-p <glob>` - "Patch," adds only some lines of a given file to the stage. Starts an interactive displaying of different code sections where you select if you want it staged or not.
        + `y` - "Yes," add this section
        + `n` - "No," do not add this section
        + `a` - "Yes to all," add the rest of the changes in this file
        + `d` - "No to all," don't add any of the remaining sections in the file
        + `e` - *Edit* - Open the section in the configured editor to fine-tune what is and isn't added
    - `-N <glob>` - Adds untracked files to git's index.
* **`git commit`** - Create a new commit with the staged files.
    - Defaults to opening the configured `core.editor` for adding a message.
    - `-m "<message>"` - Add a message for the commit.
    - `git commit -m "<message>" -m "<description>"` - Two `-m` flags, one after another, allows you to add a longer description to give better context for a commit.
        + e.g. From [Terms](#terms) > Commit: `git commit -m "MAS-3238 Bug fix: Make mock sessionStorage.getItem() return null if key not found" -m 'In JavaScript, attempting to get the value of an object that lacks the specified ... (rest of text)'`
    - Opening the core.editor is helpful if the description portion is very long, or you want to format it with markdown for easier reading.
    - `--amend` - Edits the last commit with any currently staged files and new message.
        + Useful if you forgot a file/code section in the previous commit or want to change the commit message.
        + Best used only if your commit has not been pushed up to a remote repository (otherwise, you'll have diverged branches).
* **`git push`** - Push your local commits on the current branch to the remote repository.
    - `-u <remote-nickname> <new-branch-name>` - Pushes a new branch to the specified remote repository.
    - Usually, your command will look like `-u origin <new-branch-name>`.
* **`git merge <branch-name>`** - Merges the changes from branch-name into your current branch.
    - Most common command for updating your current branch with the changes made in a different branch.
    - Will be one of the most useful commands when there are merge conflicts in your pull-request, and you need to pull in the changes from the destination branch to your source branch before being able to merge.
* **`git fetch <remote>`** - Fetches (but does not merge/overwrite files) all updated information for all branches from the specified remote.
    - Remote defaults to `origin`.
* **`git pull <remote> <branch-name>`** - Combination of `git fetch <remote>` and `git merge remote/branch-name`.
    - Remote defaults to `origin`.
    - branch-name defaults to your current branch.

### Advanced Commands

* **`git reset`** - Resets your local repository to a specific point in time.
    - Can use either the commit hash (don't need full hash, but at least 6 characters) or `HEAD~n` where *n* is the number of commits before HEAD.
        + `HEAD~` == `HEAD~1` == `HEAD^`.
    - `--soft <commit>` - Resets HEAD pointer to the commit specified, but doesn't unstage or overwrite files.
    - `--mixed <commit>` - Resets HEAD pointer to the commit specified and unstages files, but does not overwrite them.
    - `--hard <commit>` - Resets HEAD pointer to the commit specified and both unstages and overwrites files.
    - Defaults to `--mixed`.
    - `--<mode> <commit> -- <glob>` - Resets HEAD pointer to the commit specified using the specified mode, but only for files/directories matching the glob pattern.
* **`git stash`** - Saves all your staged/unstaged changes in git and hard-resets the working directory.
    - Useful for doing git operations on your branch that require a clean working directory (such as merging and rebasing) and for saving some changes for a later commit.
    - Can stash some or all files.
    - Can have multiple stash entries.
    - `save "message"` - Adds a message to the stash for easy identification of what's in that stash.
    - `apply <stash-id>` - Applies the changes in the specified stash to your working directory. Defaults to the latest stash entry, `stash@{0}`.
    - `drop <stash-id>` - Deletes the specified stash from the list of stash entries. Defaults to the latest stash entry.
    - `pop <stash-id>` - Combination of `apply` and `drop`. Defaults to latest stash entry.
    - `list` - List all stash entries, including stash IDs and messages.
    - `push` - More powerful `save` that allows stashing only some lines and/or some files.
        + `-m "message"` - Add a message to the stash entry.
        + `-p` - "Patch," only stash some lines, same concept as `git add -p`.
        + `-- <glob>` - Only stash files matching the glob pattern.
* **`git revert <commit>`** - Undoes a commit, leaving it in the history.
    - Very helpful to undo a commit when working with remote repositories since `git push -f` is highly discouraged (and blocked on some repositories).
* **`git cherry-pick <commit>`** - Copies the changes of the specified commit onto your branch.
    - Useful if you need the changes from a different branch in your branch.
        + e.g. You made commits in the wrong branch and need them in another branch.
        + e.g. You can't run `git revert` since other code was added after that commit, so you copy the commits you want to a new branch without that commit one-by-one.
* **`git rebase`** - Allows you to rewrite history.
    - Can only be done with a clean working directory (so stash any changes you want to keep).
    - `-i <commit>` - Rebases in interactive mode. Will first pull up a screen to let you choose what to do with each commit, followed by subsequent screens that allow you to apply your changes and/or exiting the core.editor to allow you to modify a commit.
    - Using `-i` is particularly helpful instead of manually specifying squash, edit, drop, etc. because it displays what each action does in your editor in case you forgot what does what.

### Util Commands

* **`git config`** - Configure git to function the way you want.
    - `--global` - Configure a global setting. Without this flag, it only changes the configs in the current repository.
    - `user.name <name>` - Set your username.
    - `user.email <email>` - Set your email.
    - `core.editor "<command>"` - Set the default editor to open for interactive git commands, such as `git commit`, `git add -p`, and `git rebase -i`.
        + e.g. `git config --global core.editor "subl -n -w"` - Run the command `subl -n -w` whenever an interactive git action is taking place.
        + `-n` to open a new window, `-w` to make git wait for the Sublime window to close before continuing
* **`git clean`** - Cleans the working directory of untracked files.
    - `-n` - Displays, but doesn't delete, files that would be deleted in `git clean -f`.
    - `-f` - Deletes untracked files.
* **`git remote`** - Alter remote repositories.
    - Defaults to `show` - displaying remote nicknames.
    - `-v` - Show nickname-URL mappings.
    - `add <nickname> <url>` - Adds a new remote at the specified URL and names it.
    - `remove <nickname>` - Removes the specified remote repository.
* **`git blame`** - Shows the latest commit hashes, messages, authors, and dates for particular file(s).
* **`git log`** - More detailed `git blame` that shows the commit history and/or the files changed and/or the lines changed.
    - Lots of different options, run `git log --help` to see them all.
    - `--stat` - Shows which files were changed in each commit, along with how many lines were changed in those files.
    - `--graph` - Pretty-prints the `git log` output with colored branch lines on the left of the output.
    - `-p|--patch` - Shows the lines changed in each commit.
    - `--oneline` - Compresses the `git log` output to single lines. Can still be combined with other options.
    - `--all` - Shows the log for all branches (not just the branch you're on) as well as when stash entries were made.
    - `--first-parent <branch-name>` - Only show the commits in a specific branch. Useful for filtering out only the changes on your branch to reduce the noise of log output. Will stil include all commits made before the branch was created.
* **`git update-index`** - Make changes to git's index to alter the way it reads and tracks files.
    - Like `git log`, has lots of different options, so run `--help` to see them all.
    - `--assume-unchanged <glob>` - Allows your local changes to remain in the specified file(s) without them showing in `git status` or being accidentally added when running `git add *`.
    - `--no-assume-unchanged <glob>` - Undoes `--assume-unchanged <glob>`

## Best Practices

### Commits

* Write **good commit messages and descriptions**.
    - Good messages/descriptions are extremely helpful to explain why a change was made, especially when **code comments aren't really appropriate**.
    - For example, if I changed a CSS class on an HTML element to assist with centering, it would likely be both superfluous and annoying if I added a comment in the code explaining why `margin: auto;` didn't work but `text-align: center;` did.
    - In this case, it would be super helpful to have a message somewhat along the lines of
    ```
    Bug fix: Center text within div
    ```
    and a description of
    ```
    `margin: auto` centers HTML elements, but not the content inside them.
    Since text is not an HTML element, it isn't affected by margin changes,
    and requires its own special CSS style, `text-align`. Thus, center text
    within the div by swapping the .m-auto Bootstrap class with .text-center.
    ```
* Make **small, incremental commits** instead of large "god" commits.
    - Multiple small commits allow the team to be able to operate on the repository's history much easier than when they see a god commit with a generic description, such as "Add new endpoint to do X." This includes:
        + Reverting code
        + Cherry-picking commits
        + Better understanding of what changes were associated with a particular line of code when using `git blame`/`git log -p`.
    - `git add -p` is an incredibly useful tool to assist with this because it allows you to **select small parts of code to make commits** even when you have made many changes in a repository.
        + Sometimes, features require lots of changes before you can verify that foundational code blocks work correctly.
        + e.g. Adding a new util function in the process of adding a new endpoint, but you need that endpoint in order to call that function.
        + In these situations, you could essentially code the entire feature without any commits, and then selectively commit portions of code so that the repository history is dev-friendly while also not impeding your work flow.
* The reason incremental commits with good messages are helpful **isn't apparent at first**, rather months down the line.
    - This is especially true when you and your team don't remember the exact reason why a piece of code was changed or why it exists in the first place.
    - In this case, it makes a world of difference to read a good commit message and see only the changes related to that change instead of seeing lots of other code unrelated to the change.
    - `git blame` and `git log -p` become your best friends in these cases!
* It's **not always clear** what a worthy incremental commit looks like; it's a learning experience/play-by-ear activity.
    - When should one change be broken down into multiple commits, and vice versa?
    - Sometimes one type of incremental commit in one situation isn't incremental in another.
        + e.g. Adding a constant variable in a separate commit or with a new function addition: either could be justified.
        + e.g. Changing src/tests in one commit works sometimes but not others.
    - General **rules of thumb** I use:
        + Could I add a helpful commit description for this or not?
        + Are the changes of the same category/result or different?
        + Does this change add anything useful to the code base (regardless of if it's used or not)?
* Some samples of incremental commits with good messages:
    - https://bitbucket.etrade.com/projects/WEBC/repos/design-language-react/pull-requests/197/commits
    - https://github.com/spring-projects/spring-boot/commit/e4fa9ce8c6751f4ad696ff75b7783b7f7af516f9
        + Great message, but could be improved by splitting into multiple commits, at least for src/test files.

### Code Reviews

* Code reviews take place for every pull-request.
* They are a great way to share ideas and learn from one another.

Things to keep in mind:

* Don't take comments personal; **assume best intent**.
    - Tone doesn't travel through text.
    - Comments are often short and to the point, which could come across as rude. It's unlikely the reviewer was trying to be rude when they wrote that.
    - If someone asks for you to rewrite or refactor the code, it's not a slight on your coding skills. In fact, it serves as a great learning opportunity.
* Likewise, **be conscientious of your wording**.
    - Rephrasing a command to a question often both softens the comment and invites a conversation instead of just an "okay, will do" response.
    - Try to avoid "you" when possible. Replace with "I feel like..." or "Do you think..."
    - IMO I've found adding "Nit: " (stands for nitpick) before the rest of the comment helpful when it deals with minor code improvements that don't break functionality (e.g. variable naming, strange indentions, extracting repeated code to a function, etc.).
* **Don't be shy** when commenting.
    - If you have trouble understanding what's going on, ask!
    - No one will be disappointed with a curious mind.
    - You may be thinking of an important edge case that, if you stayed silent, would become a bug later on.
* Compliments are helpful, not noise.
    - If you really like what someone did or thought it was crafty, let them know!
    - It doesn't add noise to the PR or annoy people to see a teammate lifting up a fellow teammate.
* You can **comment on your own PR** to give context or clarify a change.
    - Sometimes git makes strange decisions in where it decides to mark lines as added/removed which could make some code blocks display more added/removed lines than what you actually did.
    - If you were to comment on that code block to call out e.g. the one line that was actually changed vs the lines that changed based only on spacing, it would help reviewers to filter out the red and green noise of the code surrounding the part that's actually important.
    - You can also **request teammates' opinion** on pieces of code that you were on the fence about. This would be a great chance to learn a new perspective and improve yourself!
    - Examples:
        + Clarifying a change (with images): https://bitbucket.etrade.com/projects/WEBP/repos/react-mutualfundsandetf/pull-requests/1319/overview
        + Asking for advice: https://bitbucket.etrade.com/projects/WEBP/repos/react-mutualfundsandetf/pull-requests/1261/overview
* Change the **PR title to reflect the main change** that was done.
    - More helpful than just leaving the pre-filled Jira ticket number alone.
* Always get at least one approval before merging a PR.
    - Even if an approval isn't marked as necessary by the repository's permissions/rules.
* Take the time to **add a helpful description** for the PR. Your teammates will be grateful.
    - BitBucket defaults to pre-filling the description with commit messages.
    - It helps to replace them with a few paragraphs/bullet-points that summarize what you did and why.
    - This is a lot more readable than a list of commits.
    - You can still see a list of commits in the "Commits" tab, so they are still visible.
    - You can add images to your PR description if it helps in understanding what's going on. Particularly helpful for front-end design tweaks.
    - Unlike the message in a single commit, the PR description covers all commits. It can be helpful to split the description into sections, such as "Primary/Secondary Additions" or "Source/Test Changes" or "File A/File B/..."
    ```
    This PR adds various customizations to the rendered icon.

    Primary additions:
    * The ability for the user to apply CSS classes to the icon
    * The ability to toggle on/off the rotation of the icon upon expanding content
    * The ability to put the icon to the right of the label instead of always on the left

    Also in this PR:
    * Fix classnames() not reading arguments keyword properly
    * Fix React error 'Children in arrays must have unique keys'
        - The logic to change the btnChildren declaration order in ExpandCollapse was simplified by
          using an array. However, this array causes React to throw an error claiming they must have
          unique keys. Fix that by specifying the two children of the array individually instead of
          just rendering the array directly.
    * Remove deprecated class declaration
    ```
    or
    ```
    This PR refactors the front-end code base to call an endpoint to get the frequency-investmentDay
    mappings array instead of using a hard-coded constant, allowing the back-end to be the single
    source of truth for frequency IDs (i.e. frequencyCode) and displayed text.

    Source changes:
    * Add API call to new endpoint `/getFrequenciesAndInvestmentDays`
    * Set the results of the API call to new sessionStorage field
        - Caches the response only for the browser session
        - Allows subsequent page loads to be quicker
        - Data will be up-to-date since sessionStorage is cleared when the browser closes
    * Add new `Store.getFrequencyMapping()` util function for getting frequency mappings. Includes:
        - Getting single mapping based on `frequencyName`, `frequencyCode`, or index in mappings
          array
        - Getting the whole array with or without the backwards-compatible
          "When funds available" option
    * Replace `FREQUENCY_MAPPING` usage with new util function

    Test changes:
    * Enhance testSetup.js
        - Fix mock sessionStorage object to return `null` instead of `undefined` if key not found
          to match actual sessionStorage object in the browser
        - Add mocks for `fetch` and `XHR` for easier network mocking using `MockRequests`
        - Mock design-language's `Flyout` component since it was the source of many of the erroneous
          errors printed to the console when testing
    * Add tests for each option in new `Store.getFrequencyMapping()`
    * Replace `FREQUENCY_MAPPING` usage with new util function
    ```
* No one is always right.
    - There have been times I commented on a PR to request a change just to find out the change would've broken something else.
    - There have also been times someone commented on my PR requesting a change and, after I explained why I made those changes how I did, they ended up agreeing with me.
    - Again, PR comments are a *conversation*, not a one-way street where all suggested changes should be made.
* Pick your battles.
    - Remember, **you're a team first**, and a reviewer second.
    - Sometimes, especially when I've made many other comments on the PR, I'll decide not to make a new minor "Nit" suggestion so I don't overwhelm the other person.
    - Similarly, sometimes it's reasonable to postpone a really good suggestion to a future PR and/or make a new Jira ticket in the backlog so it doesn't get forgotten so you can merge your code in the interest of time.
    - On the other hand, if the PR would break something or go against library guidelines, it would be worthwhile to not postpone the change to a future PR/Jira ticket.
* Be patient and understanding.

## Shortcuts

    "Doing incremental commits sounds like a great idea,
    but what about all the time spent typing in the terminal?"

Something I've personally found very helpful to speed up my work flow are **aliases and functions** for commands I use frequently. For example, some of the aliases I use include:

```
// ~/.profile
alias  gs='git status'
alias  gd='git diff'
alias gdc='git diff --cached'
alias  gc='git commit -m'       # gc "MAS-1234 My message" -m "Long description"
alias gac='git commit -am'      # same as `gc` but adds all files

getGitBranch() {
    # sed: replace '* ' with ''
    git branch | grep '*' | sed -E 's|(^\* )||'
}

alias   gpu='git push -u origin $(getGitBranch)'
```

These aliases/functions become very useful for automating git functions and speeding up your work flow.

For example, in this company, it is required to include a Jira ticket ID with every commit so it can be tracked. Since it becomes quite tedious over time to remember the Jira ticket and type it in every commit, you could use a terminal autocomplete function to fill it out for you with aliases and functions, assuming your branch is named `(feature|hotfix|bugfix)/JIRA-1234-optionalBranchDescription`.

e.g. If you use a Mac, there is a built-in `complete` function that defines how `Tab` works in the terminal. I like to use that to type `gc [Tab]` and have it add the Jira ticket as a prelude to my commit message:

```
# Make bash autocomplete when tabbing after "git commit" alias like gc or gac
autocompleteWithJiraTicket() {
    # sed -rEgex
    #   'substitute|Jira ticket at start of branch regex|\1 = extract matching text only|'
    branch=$(getGitBranch | sed -E 's|.*/([A-Z]+-[0-9]+).*|\1|')
    COMPREPLY=$branch
    return 0
}

# Requires alias because spaces aren't allowed (so can't use `git commit`)
# -P = Character with which to prepend text.
#   Set to use `"` but you could use `'` instead to allow back-ticks, `, in
#   your messages.
complete -F autocompleteWithJiraTicket -P \" "gc"
complete -F autocompleteWithJiraTicket -P \" "gac"
```

This will make `gc [Tab]` autocomplete in the terminal to `gc "JIRA-1234 ` which will allow you to type your git commit message after the Jira ticket number. Just remember to close it off with a `"` at the end.
