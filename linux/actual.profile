dotfilesDir='/home/dpow/Documents/Repositories/dotfiles'

if [[ -d "$dotfilesDir" ]]; then
    source "$dotfilesDir/.profile" 'linux'
fi
