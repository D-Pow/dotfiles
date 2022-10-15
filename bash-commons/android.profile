androidDevices() {
    declare _androidDevicesReturnArray=
    declare _androidDevicesPairedOnly=
    declare _androidDevicesIdOnly=
    declare argsArray=
    declare USAGE="[OPTIONS...]
    Gets all physical Android devices available for connecting via KDE-Connect, \`adb\`, etc.

    See:
        - https://userbase.kde.org/KDE_Connect/Tutorials/Useful_commands
    "
    declare -A _androidDevicesOpts=(
        ['r|return-map:,_androidDevicesReturnArray']='Variable name into which the resulting Name-ID map should be injected.'
        ['p|paired-only,_androidDevicesPairedOnly']='Only get devices paired with the computer.'
        ['d|id,_androidDevicesIdOnly']='Only return the device ID.'
        [':']=
        ['?']=
        ['USAGE']="$USAGE"
    )

    parseArgs _androidDevicesOpts "$@"
    (( $? )) && return 1

    declare IFS=$'\n'
    declare -A devices=()
    declare devicesUnformatted=$(kdeconnect-cli -l 2>&1)

    if [[ -n "$_androidDevicesPairedOnly" ]]; then
        devicesUnformatted="$(echo "$devicesUnformatted" | egrep -i 'paired')"
    fi

    devicesUnformatted=$(echo "$devicesUnformatted" \
        | egrep -iv 'devices found' \
        | esed 's/^- ([^:\s]+): (\S+) .*/\1 \2/'
    )

    declare device=
    declare deviceId=
    declare deviceName=
    for device in ${devicesUnformatted[@]}; do
        if [[ -z "$device" ]]; then
            continue
        fi

        deviceId=$(echo $device \
            | esed 's/.*[\s\S]*\s(\S+)$/\1/' \
            | trim
        )
        deviceName=$(echo $device \
            | awk '{ $NF=""; print $0; }' \
            | trim \
            | esed 's/\s+/_/g'
        )

        devices["$deviceName"]="$deviceId"
    done

    for deviceName in "${!devices[@]}"; do
        deviceId="${devices["$deviceName"]}"

        if ! array.empty argsArray; then
            # Custom filter from user
            if ! $(echo "$deviceName $deviceId" | egrep -q "${argsArray[@]}"); then
                continue
            fi
        fi

        if [[ -n "$_androidDevicesReturnArray" ]]; then
            declare -n _retArr="$_androidDevicesReturnArray"

            if [[ -n "$_androidDevicesIdOnly" ]]; then
                _retArr+=("$deviceId")
            else
                _retArr["$deviceName"]="$deviceId"
            fi
        else
            if [[ -n "$_androidDevicesIdOnly" ]]; then
                echo "$deviceId"
            else
                echo "$deviceName - $deviceId"
            fi
        fi
    done
}
