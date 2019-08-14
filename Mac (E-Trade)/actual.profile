dotfilesDir="/Users/dpowell1/repositories/dotfiles"
commonProfile="$dotfilesDir/Common.profile"
macProfile="$dotfilesDir/Mac (E-Trade)/mac.profile"

source "$commonProfile"
source "$macProfile"

# Overwritten profile content based on relevant paths
alias editprofile="subl -n -w '$commonProfile' && source '$macProfile'"
alias gcmd="cat '$commonProfile' | grep -e 'alias *g' | grep -v 'grep'"

export PATH="$dotfilesDir/Linux/bin:$dotfilesDir/Mac (E-Trade)/bin:$PATH"
