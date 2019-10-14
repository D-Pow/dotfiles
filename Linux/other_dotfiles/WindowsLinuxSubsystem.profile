topath () {
    readlink -m "$1"
}

towindowspath () {
    path=$(topath "$1")
    echo $path | sed -e "s@/mnt/@@" -e "s@/@:/@"
}

cmd () {
    # For some reason, flags aren't picked up in $@, $2, etc. so just parse out the command
    commandToRun="$1"
    rest=${@/$commandToRun/""}
    /mnt/c/Windows/System32/cmd.exe "/C" "$commandToRun" $rest
}

clip () {
    echo "$1" | cmd clip
}

dotfilesRepo='/mnt/d/Documents/Repositories/dotfiles'
PATH="$dotfilesRepo/Linux/bin:$PATH"
export PATH
source "$dotfilesRepo/Common.profile"

# Note: don't edit Linux subsystem files with Windows programs
# It will mess up everything
# Thus, use vim to edit .profile
alias listupdate='sudo apt update && sudo apt list --upgradable'

# Overwrite Common.profile git command location
alias gcmd="cat $dotfilesRepo/Common.profile | grep -e 'alias *g' | grep -v 'grep'"

# Add commands for programs installed on Windows
alias subl='cmd subl'
alias npm='cmd npm'
