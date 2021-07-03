dotfilesDir='/home/dpow/Documents/Repositories/dotfiles'
platform='linux'

if [[ -d '/home/dpow/Documents/Repositories/dotfiles' ]]; then
    source "$dotfilesDir/.profile" "$dotfilesDir" "$platform"
fi
