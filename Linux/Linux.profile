# User stuff
JAVA_HOME="/usr/java"
GRADLE_HOME="/opt/gradle"
export JAVA_HOME
export GRADLE_HOME
export PATH="$JAVA_HOME/bin:$GRADLE_HOME/bin:$HOME/.local/bin:$PATH"

# Change directory colors in `ls`
# LS_COLORS="${LS_COLORS}di=01;35"
# export $LS_COLORS

# [green]\username[white]:[teal]\working_directory[white]$[space]
export PS1="\[\033[01;32m\]\u\[\033[00m\]:\[\033[00m\]\[\033[01;34m\]\w\[\033[00m\]\$ "

alias listupdate='sudo apt update && sudo apt list --upgradable'

alias scan='savscan -all -rec -f -archive'

alias apachestart='/etc/init.d/apache2 start'
alias apachestop='/etc/init.d/apache2 stop'
alias apachestatus='/etc/init.d/apache2 status'

copy() {
    # Linux: xclip (will need install)
    # Mac:   pbcopy
    echo -n "$1" | pbcopy
}
