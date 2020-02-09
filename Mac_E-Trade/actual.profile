export dotfilesDir="/Users/dpowell1/repositories/dotfiles"
export commonProfile="$dotfilesDir/Common.profile"
export macProfile="$dotfilesDir/Mac_E-Trade/mac.profile"

source "$commonProfile"
source "$macProfile"

# Overwritten profile content based on relevant paths
alias editprofile="subl -n -w '$macProfile' && source ~/.profile"
alias editcommon="subl -n -w '$commonProfile' && source ~/.profile"
alias gcmd="cat '$commonProfile' | grep -e 'alias *g' | grep -v 'grep'"

export PATH="$dotfilesDir/Linux/bin:$dotfilesDir/Mac_E-Trade/bin:$PATH"
