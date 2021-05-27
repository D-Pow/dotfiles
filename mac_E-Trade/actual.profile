export dotfilesDir="/Users/dpowell1/repositories/dotfiles"
export commonProfile="$dotfilesDir/common.profile"
export macProfile="$dotfilesDir/mac_E-Trade/mac.profile"

source "$commonProfile"
source "$macProfile"

# Overwritten profile content based on relevant paths
alias editprofile="subl -n -w '$macProfile' && source ~/.profile"
alias editcommon="subl -n -w '$commonProfile' && source ~/.profile"

export PATH="$dotfilesDir/linux/bin:$dotfilesDir/mac_E-Trade/bin:$PATH"
