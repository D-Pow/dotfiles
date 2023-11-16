export windowsUser="$(whoami | sed -E 's/./\U&/g')"  # Same as `str.upper "$(whoami)"`
export windowsHome="/mnt/c/Users/${windowsUser}"
export dotfilesDir="${windowsHome}/Documents/repositories/dotfiles"
export platform='Windows/wsl'

source "$dotfilesDir/.profile" "$platform"
