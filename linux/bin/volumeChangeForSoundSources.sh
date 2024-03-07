#!/usr/bin/env bash

changeVolumeForSoundSources() {
    # See:
    #   - https://unix.stackexchange.com/questions/208784/command-line-per-application-volume-maybe-amixer-or-pactl
    #   - https://unix.stackexchange.com/questions/32206/set-volume-from-terminal
    #   - https://www.geeksforgeeks.org/amixer-command-in-linux-with-examples
    declare USAGE="[...OPTIONS]
    Modifies volume for any/all application sources outputting sound.
    Defaults to changing all by 5%.

    Options:
        -d <delta>      |   Percentage delta the volume should be changed.
        -n              |   Negate \`delta\` percentage for decreasing volume.
                        |   Shorthand for \`-d '-5%'\`.
        -s <source>     |   Sink input ID(s) from \`pactl list sink-inputs\`.
                        |   Sink inputs are the sources of sound. Outputs are devices.
    "
    declare delta=5
    declare negate=
    declare soundSources=()

    declare OPTIND=1
    while getopts "d:s:n" opt; do
        case "$opt" in
            d)
                delta="$OPTARG"
                ;;
            n)
                negate=true
                ;;
            s)
                soundSources+=("$OPTARG")
                ;;
            ?)
                echo -e
        esac
    done
    shift $(( OPTIND - 1 ))

    declare deltaArg="${negate:+-}${negate:-+}${delta}%"
    deltaArg="$(echo "$deltaArg" | sed -E 's/^([+-])+/\1/; s/%+$/%/')"

    declare allSoundSources=($(
        pactl list sink-inputs \
            | grep -P '^Sink Input' \
            | grep -P -o --color=never '(?<=#)\d+'
    ))

    if (( ${#soundSources[@]} == 0 )); then
        soundSources=("${allSoundSources[@]}")
    fi

    declare soundSource=
    for soundSource in ${soundSources[@]}; do
        pactl set-sink-input-volume $soundSource $deltaArg
    done
}



if [[ "${BASH_SOURCE[0]}" == "${BASH_SOURCE[ ${#BASH_SOURCE[@]} - 1 ]}" ]]; then
    changeVolumeForSoundSources "$@"
fi
