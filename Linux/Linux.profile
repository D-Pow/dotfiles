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

alias scan='savscan -all -rec -f -archive'

alias lah='ls -lah'


alias g='git'
alias gs='git status'
alias gd='git diff'
alias gdc='git diff --cached'
alias ga='git add'
alias gap='git add -p'
alias gc='git commit -m'
alias gac='git commit -am'
alias gb='git branch'
alias gck='git checkout'
alias gl='git log'
alias gls='git log --stat --graph'
alias gp='git push'
alias gpl='git pull'
alias gr='git reset'
alias gcmd='cat ~/.profile | grep "alias g"'
# Make bash autocomplete when tabbing after "git commit" alias like gc or gac
getGitBranch() {
    COMPREPLY=$(git branch | grep '*' | cut -d ' ' -f 2)
    return 0
}
# Requires alias because spaces aren't allowed
complete -F getGitBranch "gc"
complete -f getGitBranch "gac"
