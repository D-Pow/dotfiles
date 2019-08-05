# User stuff
PATH="$HOME/.local/bin:$PATH"

JAVA_HOME="/usr/java"
GRADLE_HOME="/opt/gradle"
export JAVA_HOME
export GRADLE_HOME
PATH="$PATH:$JAVA_HOME/bin:$GRADLE_HOME/bin"
export PATH

# LS_COLORS="${LS_COLORS}di=01;35"
# export $LS_COLORS

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
