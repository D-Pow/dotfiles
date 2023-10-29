#!/usr/bin/env bash

declare thisDir="$(realpath "$(dirname "${BASH_SOURCE[0]}")")"
declare destinationDir=

declare OPTIND=1
while getopts "d:" opt; do
    case "$opt" in
        d)
            destinationDir="$OPTARG"
            ;;
    esac
done
shift $(( OPTIND - 1 ))

destinationDir="$(realpath "${destinationDir:-"$thisDir"}")"

declare filesToCopy=("$@")

if (( ${#filesToCopy[@]} == 0 )); then
    filesToCopy=(".*")
fi

# Output: (a)|(b)|
declare fileFilterRegex="$(printf "(%s)|" "${filesToCopy[@]}")"
# Strip trailing `|`
fileFilterRegex="${fileFilterRegex/%|}"

declare pathsToSearch=(
    # Default dir
    /usr/share/mint-artwork/sounds
    # Sounds backed up from previous OS dir
    /usr/share/sounds/freedesktop/stereo
)

# Alternative
#   declare defaultSoundsPath="/usr/share/mint-artwork/sounds"
#   declare defaultSounds=($(find "$defaultSoundsPath" -type f))
#   declare prevOsSoundsPath="/usr/share/sounds/freedesktop/stereo"
#   declare prevOsSounds=($(find "$prevOsSoundsPath" -type f))
#   declare soundFiles=("${defaultSounds[@]}" "${prevOsSounds[@]}")
declare origIFS="$IFS"
declare IFS=$'\n'

declare soundFiles=()
declare pathToSearch=
for pathToSearch in ${pathsToSearch[@]}; do
    soundFiles+=($(find "$pathToSearch" -type f))
done

IFS="$origIFS"

declare filePath=
for filePath in "${soundFiles[@]}"; do 
    if echo "$filePath" | grep -Pivq --color=never "$fileFilterRegex"; then
        continue
    fi

    echo "Copying $filePath..."

    declare fileName="$(basename "$filePath")"

    sudo cp "$filePath" "$destinationDir"
    sudo chown $(whoami):$(whoami) "$fileName"
    sudo chmod g+w "$fileName"
done
