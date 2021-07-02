# Useful special bash keywords: https://www.gnu.org/software/bash/manual/html_node/Bash-Variables.html

alias thisFile='echo "$BASH_SOURCE"'
alias thisDir='echo "$(realpath "`dirname "$(thisFile)"`")"'

source "$(thisDir)/bash-command-enhancements.profile"
source "$(thisDir)/bash-history.profile"
source "$(thisDir)/os-utils.profile"
source "$(thisDir)/git.profile"
source "$(thisDir)/programs.profile"
