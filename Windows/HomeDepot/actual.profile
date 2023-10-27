export windowsUser="$(whoami | sed -E 's/./\U&/g')"  # Same as `str.upper "$(whoami)"`
export windowsHome="/mnt/c/Users/${windowsUser}"
export dotfilesDir="${windowsHome}/repositories/dotfiles"
export platform='Windows/HomeDepot'

source "$dotfilesDir/.profile" "$platform"
