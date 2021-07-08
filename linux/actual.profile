dotfilesDir='/home/dpow/Documents/Repositories/dotfiles'
platform='linux'

if [[ -d "$dotfilesDir" ]]; then
    source "$dotfilesDir/.profile" "$dotfilesDir" "$platform"
fi
