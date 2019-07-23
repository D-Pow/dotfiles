# User stuff
# set PATH so it includes user's private bin directories
PATH="$HOME/bin:$HOME/.local/bin:$PATH"

# Oracle JDK
JAVA_HOME="/usr/java"
PATH="$PATH:$JAVA_HOME/bin"
export JAVA_HOME
export PATH

# Gradle
GRADLE_HOME="/opt/gradle"
PATH="$PATH:$GRADLE_HOME/bin"
export GRADLE_HOME
export PATH

alias apachestart='/etc/init.d/apache2 start'
alias apachestop='/etc/init.d/apache2 stop'
alias apachestatus='/etc/init.d/apache2 status'

alias listupdate='sudo apt update && sudo apt list --upgradable'

alias editprofile="subl -n -w ~/.profile && source ~/.profile"

alias scan='savscan -all -rec -f -archive'

alias lah='ls -lah'

npms() {
    # regex is homemade ~/bin/regex python script
    regex '"scripts": [^\}]*\}' ./package.json
}
alias npmr='npm run'
alias grep='grep --exclude-dir={node_modules,.git,.idea,lcov-report}'
alias egrep='egrep --exclude-dir={node_modules,.git,.idea,lcov-report}'
gril() {
    grep "$1" -ril .
}


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
alias gckb="git checkout $bl"
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
