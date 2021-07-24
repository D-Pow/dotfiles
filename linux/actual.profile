dotfilesDir='/home/dpow/repositories/dotfiles'

if [[ -d "$dotfilesDir" ]]; then
    source "$dotfilesDir/.profile" 'linux'
fi
