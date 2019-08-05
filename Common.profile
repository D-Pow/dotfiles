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

npms() {
    # regex is homemade ~/bin/regex python script
    regex '"scripts": [^\}]*\}' ./package.json
}
alias npmr='npm run'

alias    g='git'
alias   gs='git status'
alias   gd='git diff'
alias  gdc='git diff --cached'
alias   ga='git add'
alias  gap='git add -p'
alias   gc='git commit -m'
alias  gca='git commit --amend'
alias  gac='git commit -am'
alias   gb='git branch'
alias  gbd='git branch -d $(git branch | grep -v "*")'
alias  gck='git checkout'
alias   gl='git log --stat --graph'
alias  glo='git log --stat --graph --oneline'
alias  gla='git log --stat --graph --oneline --all'
alias   gp='git push'
alias   gr='git reset'
alias  grH='git reset HEAD'
alias  grh='git reset --hard'
alias grhH='git reset --hard HEAD'
alias  gpl='git pull'
alias  gst='git stash'
alias gsta='git stash apply'
alias gsts='git stash save'
alias  gau='git update-index --assume-unchanged'
alias gnau='git update-index --no-assume-unchanged'
alias  gaud='git update-index --assume-unchanged src/data/mocks/DefaultPageConfig.js'
alias gnaud='git update-index --no-assume-unchanged src/data/mocks/DefaultPageConfig.js'
alias gcmd='cat ~/.profile | grep -e "alias *g" | grep -v "grep"'

# Open merge conflict files
gcon() {
    subl $(gs | grep both | sed 's|both modified:||')
}