# Note: DO NOT USE QUOTES when using ~
# Otherwise, it won't be expanded (just like how globs in quotes aren't expanded)
dotfilesDir=~/repositories/dotfiles

if [[ -d "$dotfilesDir" ]]; then
    source "$dotfilesDir/.profile" 'linux'
fi
