abspath() {
    declare _path="${1:-.}"

    # Without flags, `realpath` is the same as `readlink` if the path
    # exists; however, if it doesn't, `realpath` will still resolve the
    # specified path even though it doesn't exist.
    #
    # Both follow symlinks.
    #
    # `-e` ensures the path exists for both of them, which fixes that issue.
    # `realpath -e` will print an error whereas `readlink -e` does not.
    # This is helpful in this case since we're using it in tandem with other commands.
    #
    # `type -P` will traverse $PATH to try to find the file if it isn't found by `readlink`.
    #
    # Ref: https://stackoverflow.com/a/66044002/5771107
    readlink -e "$_path" || type -P "$_path" || { echo "'$_path' not found." >&2 && return 1; }
}

filename() {
    # See: https://stackoverflow.com/questions/965053/extract-filename-and-extension-in-bash
    declare USAGE="[OPTION]... <file>...
    Gets the filename of a file.
    Optionally, selects only the leading name with(out) sub-extensions, all sub/final extensions, or final extension.

    For example, the below option flags handle the file \"example.tar.gz\" in different ways.
    "
    declare _onlyLeadingName=
    declare _onlyLeadingNameAndSubExtensions=
    declare _onlySubAndFinalExtensions=
    declare _onlyFinalExtension=
    declare _keepLeadingPath=
    declare argsArray
    declare stdin
    declare -A _filenameOptions=(
        ['l|leading-name,_onlyLeadingName']='Only print the leading name before periods (e.g. `example`).'
        ['n|name-and-sub-exts,_onlyLeadingNameAndSubExtensions']='Only print the leading name and sub extensions (e.g. `example.tar`).'
        ['s|sub-and-final-exts,_onlySubAndFinalExtensions']='Only print the sub and final extensions (e.g. `tar.gz`).'
        ['e|ext,_onlyFinalExtension']='Only print the final, "real" extension (e.g. `gz`).'
        ['p|keep-leading-path,_keepLeadingPath']='Prepends the leading path to the filename selection output (e.g. `./path/to/example.tar`).'
        ['USAGE']="$USAGE"
    )

    parseArgs _filenameOptions "$@"
    (( $? )) && return 1


    declare _filenamesToParse=("${stdin[@]}" "${argsArray[@]}")

    declare _file
    for _file in "${_filenamesToParse[@]}"; do
        declare _filename="$(basename "$_file")"
        declare _filenameSubSection="$_filename" # default to the full filename

        if [[ -n "$_onlyLeadingName" ]]; then
            _filenameSubSection="${_filename%%.*}"
        elif [[ -n "$_onlyLeadingNameAndSubExtensions" ]]; then
            _filenameSubSection="${_filename%.*}"
        elif [[ -n "$_onlySubAndFinalExtensions" ]]; then
            _filenameSubSection="${_filename#*.}"
        elif [[ -n "$_onlyFinalExtension" ]]; then
            _filenameSubSection="${_filename##*.}"
        fi

        declare _filenameOutput="$_filenameSubSection"

        if [[ -n "$_keepLeadingPath" ]]; then
            _filenameOutput="$(str.replace -s "$_filename" "$_filenameOutput" "$_file")"
        fi

        echo "$_filenameOutput"
    done
}


# _parentDir=node_modules
# _dirFilterGlob='*cypress*'
# -i node_modules
filesContaining() {
    declare _parentDir=
    declare _dirFilterGlob=
    declare _ignoredDirs=()
    declare _fileToParse=
    declare _parseJsonFile=
    declare -A _filesContainingOptions=(
        ['p|root-dir,_parentDir']='Top-level directory to search in (default: .).'
        ['d|nested-dir,_dirFilterGlob']='Glob specifying a restricted set of nested directories to search in.'
        ['i|ignore,_ignoredDirs']='Nested directories to ignore when searching.'
        ['f|file,_fileToParse']='File within the nested directories to parse for specific string(s).'
        ['j|json,_parseJsonFile']='Parse the files as JSON rather than plain text.'
    )

    declare _filteredDirs=($(find "$_parentDir" -type d ${_dirFilterGlob:+-iname "$_dirFilterGlob"}))
    declare _ignoredDirsOptions

    array.map -r _ignoredDirsOptions _ignoredDirs 'echo "-i \"$value\""'

    declare _nestedDir
    for _nestedDir in "${_filteredDirs[@]}"; do
        declare _matchingFiles=($(findIgnoreDirs -i node_modules "$_nestedDir" -name package.json))

        declare _matchingFile
        for _matchingFile in "${_matchingFiles[@]}"; do
            jq -r "try
                [
                    (.dependencies | to_entries[]),
                    (.devDependencies | to_entries[])
                ][]
                | select(.key | test(\"cypress\"))
                | .value
            " $_matchingFile
        done
    done
}


timestamp() {
    # Creates a readable timestamp using all the useful fields and none of the useless ones.
    # e.g. `12/31/2020-15:31:05_(EST)`
    #
    # Refs:
    #   https://stackoverflow.com/questions/17066250/create-timestamp-variable-in-bash-script/69400542#69400542
    date '+%m/%d/%Y-%H:%M:%S_(%Z)'
}

setLogLevel() {
    echo 'TODO'
    # See: https://stackoverflow.com/questions/36002654/create-quiet-mode-by-supress-stdout-bash-script
}


isLinux() {
    os-version -o | grep -iq 'Linux'
}

isMac() {
    # TODO Find out how to distinguish M1 macs from normal macs
    os-version -o | egrep -iq 'mac|darwin|osx'
}

isWindows() {
    os-version -o | egrep -iq '(CYGWIN)|(MINGW)'
}


bytesReadable() {
    declare USAGE="[OPTIONS...] <input-or-stdin...>
    Converts numbers from bytes to readable sizes (B, KB, MB, GB, etc.).
    "
    declare _bytesReadableDecimalPlaces=
    declare _bytesReadableDecimalPlacesDefault=2
    declare _bytesReadableRemoveSpace=
    declare argsArray=
    declare stdin=
    declare -A _bytesReadableOptions=(
        ['d|decimals:,_bytesReadableDecimalPlaces']="Number of decimal places to round to (default: $_bytesReadableDecimalPlacesDefault)."
        ['s|no-spaces,_bytesReadableRemoveSpace']="Remove the space between file size and unit."
        ['USAGE']="$USAGE"
    )

    parseArgs _bytesReadableOptions "$@"
    (( $? )) && return 1

    declare _bytesReadableNumbersArray=(${stdin[@]} ${argsArray[@]})
    declare _bytesReadablePrintfFormat="%.${_bytesReadableDecimalPlaces:-$_bytesReadableDecimalPlacesDefault}f"

    declare _bytesReadableString="$(numfmt --to=iec --suffix=B --format="$_bytesReadablePrintfFormat" "${_bytesReadableNumbersArray[@]}")"

    if [[ -n "$_bytesReadableRemoveSpace" ]]; then
        echo "$_bytesReadableString"
    else
        echo "$_bytesReadableString" | sed -E 's/([0-9])([a-zA-Z])/\1 \2/'
    fi
}


mkdirs() {
    declare _allDirs=("$@")

    declare _dirToCreate

    for _dirToCreate in "${_allDirs[@]}"; do
        # Native implementation
        mkdir -p "$_dirToCreate"

        if ! (( $? )); then
            # Successful nested-dir creation, continue to the next dir tree
            continue
        fi

        # Manual implementation, iff native call fails
        declare _dirsToCreate=

        array.fromString -d '/' -r _dirsToCreate "$_dirToCreate"

        # Use `=` to reset variable, avoiding carry-over from the previous iteration
        #   Not sure why it's carry-over, but it is
        declare _nestedParentDir=
        declare _nestedDir=
        for _nestedDir in "${_dirsToCreate[@]}"; do
            mkdir "${_nestedParentDir}${_nestedParentDir:+/}${_nestedDir}" 2>/dev/null # ignore errors from dirs already existing

            _nestedParentDir+="${_nestedParentDir:+/}${_nestedDir}"
        done

        echo "${_dirToCreate}"
    done
}


accumulate() {
    # TODO - Look at `zipSizeAfterGzipped`
    echo
}


aggregate() {
    # See: https://www.unix.com/shell-programming-and-scripting/51129-column-sum-group-uniq-records.html
    # TODO Allow aggregating by multiple columns
    declare USAGE="[OPTIONS...] <column-to-sum> [string-or-stdin]
    Sums up all numbers in one column (argument) according to equal entries in another (option).
    "
    declare _aggregateColumnToSumBy
    declare argsArray
    declare -A _aggregateOptions=(
        ['c|column:,_aggregateColumnToSumBy']="The column(s) that will remain while summing up the column defined in <argument>."
        ['USAGE']="$USAGE"
    )

    parseArgs -i _aggregateOptions "$@"
    (( $? )) && return 1

    declare _aggregateColumnToSum="${argsArray[0]}"
    declare _aggregateInput="${argsArray[@]:1}"
    declare _aggregateAwkCmd="
        {
            # Note: This cannot be done in a BEGIN block since the line hasn't been read yet
            map[\$$_aggregateColumnToSumBy] += \$$_aggregateColumnToSum;
        }

        END {
            for (i in map) {
                print i, map[i]
            }
        }
    "

    if [[ -n "$_aggregateInput" ]]; then
        echo "$_aggregateInput" | awk "$_aggregateAwkCmd"
    else
        # Allow `awk` to read from STDIN itself instead of us using `read` and forwarding that along to `awk`
        awk "$_aggregateAwkCmd"
    fi
}


listprocesses() {
    # `ps aux` has been deprecated, and only marginally supported now.
    # Now you have to specify everything manually.
    #
    # As a replacement:
    # `-A` = `-a` except implies `-x`.
    # `-a` = Include processes you do and don't own. Excludes those without controlling (TTY) terminals.
    # `-x` = Include processes without controlling (TTY) terminals.
    # `-o` = Columns you want.
    #
    # Theoretically, `ps -A` == `ps -ax` but we're using `-Ax` for safe keeping.
    declare _psOptsDefault='-Ao user,pid,ppid,%cpu,%mem,vsize,rss,tty,stat,start,time,command'

    declare USAGE="[options] [\`grep -P\` options/args]
    Runs \`ps\` with the specified options and searches for the specified string with the most supportive (Perl) regex.

    Defaults to the same headers as the obsolete \`ps aux\` would show, and removes the \`grep\` process
    from the output to avoid needing to use \`ps [args] | grep -v grep | grep -P [what-you-want]\`.

    Default \`ps\` options:
        $_psOptsDefault
    "
    declare _psOpts=
    declare argsArray=
    declare -A _lsPsOptions=(
        ['a|append:,_psOptsDefault']='`ps` options to append to the default options (before calling `grep`); e.g. `-a "-U root"`'
        ['o|overwrite:,_psOpts']='`ps` options to overwrite the default options (before calling `grep`); e.g. `-o "-o ppid= 1234"`'
        [':']=
        ['?']=
        ['USAGE']="$USAGE"
    )

    parseArgs _lsPsOptions "$@"
    (( $? )) && return 1


    _psOpts="${_psOpts:-${_psOptsDefault[@]}}"


    declare _psCommand=(ps ${_psOpts[@]}) # Don't quote to preserve spaces from input string
    # Actual `ps` command
    declare _psOutput=$(${_psCommand[@]})
    # Include header info for what each column means
    declare _psHeaders="$(echo "$_psOutput" | head -n 1)"
    # Results to `grep` through - requires the headers be removed
    declare _psResults="$(echo "$_psOutput" | tail -n +2)"
    # Options for `grep -[PE]`
    declare _egrepOptions="${argsArray[@]}"
    # array.toString _psCommand >&2

    if [[ -n "$_egrepOptions" ]]; then
        # Print info for the desired search query.
        # Filter out the `grep` command that searches for said query
        # since it's just noise.
        # Note: grep flags can still be passed by using this method.
        _psResults="$(echo "$_psResults" | grep -v grep | egrep $_egrepOptions)"

        if [[ -n "$_psResults" ]]; then
            echo "$_psHeaders"
            echo "$_psResults"
        fi
    elif [[ -n "$_psResults" ]]; then
        # Otherwise, standard command output includes headers,
        # so no manual interaction needed.
        echo "$_psOutput"
    fi
}

listopenports() {
    declare _listopenportsCmd=()
    declare OPTIND=1

    while getopts "s" opt; do
        case "$opt" in
            s)
                _listopenportsCmd+=('sudo')
                ;;
            ?)
                continue
                ;;
        esac
    done

    shift $(( OPTIND - 1 ))

    # -P - Show full port numbers (`:8080` instead of `:http-alt`)
    # -n - Show full IPs (`127.0.0.1:46012` instead of `ip6-localhost:46012`)
    # -i - Show ONLY internet addresses (default `lsof` shows all open files, including processes)
    #      `-i` arg follows the format:
    #          [46][protocol][@hostname|hostaddr][:service|port]
    #      e.g.
    #          `-i 4`/`-i 6` for showing IPv4/6
    #          `-i :PORT` for showing specific port
    _listopenportsCmd+=('lsof' '-Pn' '-i')  # `-i` doesn't have to be separate, but this clarifies that it accepts args

    if [[ -n "$1" ]]; then
        # Since the `-i` arg format is very specific, just search manually for the user's
        # input to make the function more user-friendly (so they aren't forced to know
        # the `-i` arg format).
        #
        # Also, keep the header showing what each column represents by also capturing
        # keywords in the `lsof` output header.
        # Use a lookahead so that the header capture isn't colorized, otherwise both
        # the header and the search query would be colorized.
        _listopenportsCmd+=("|" "egrep" "'(?=PID.*NAME)|$1'")
    fi

    # Use `eval` instead of just `${cmd[@]}` because pipes (`|`) are really difficult to
    # escape when trying to execute the array entries directly.
    # At least running it as an array instead of a string means spaces are maintained
    eval "${_listopenportsCmd[@]}"
}

listnetworkdevices() {
    # -sL = List devices (don't execute any commands on them)
    # --min-parallelism = Force `nmap` to be more performant via multithreading
    #   See:
    #       - https://stackoverflow.com/questions/32259953/how-to-make-nmap-command-steady-and-the-fastest-possible
    #       - https://superuser.com/questions/261818/how-can-i-list-all-ips-in-the-connected-network-through-terminal-preferably
    # egrep = Remove superfluous STDOUT info
    declare _localIpAddress="$(getip -l)"
    # e.g. `192.168.0.0/24` or `10.10.7.0/24`
    declare _lanIpAddressRange="$(getip -l | sed -E 's/\.[0-9]+$/.0/')/24"

    declare _listWithoutParentheses=
    declare _listVerbose=
    declare argsArray=
    declare USAGE="[OPTIONS...] [nmap-options...]
    Shows all devices on the same LAN network as the local computer.
    "
    declare -A _listNetworkOpts=(
        ['q|quiet,_listWithoutParentheses']='List devices without parentheses and other info.'
        ['v|verbose,_listVerbose']='Show performance stats from `nmap`'
        ['USAGE']="$USAGE"
    )

    parseArgs _listNetworkOpts "$@"
    (( $? )) && return 1

    declare _nmapOpts="${argsArray[@]}"

    declare _allDevicesStdout="$(
        nmap -sL --min-parallelism 100 $_nmapOpts "$_lanIpAddressRange" \
            | egrep -iv '^(starting nmap)|(nmap scan report for (\d{1,3}\.){3}\d{1,3}$)'
    )"

    if [[ -n "$_listWithoutParentheses" ]]; then
        # Strip parentheses from IP addresses, then remove all `nmap` performance output
        _allDevicesStdout="$(
            echo "$_allDevicesStdout" \
                | esed 's/\((([0-9]{1,3}\.){3}[0-9]{1,3})\)$/\1/' \
                | egrep -io --color=never '[^\s\t\n\r]+ [0-9.]+$'
        )"
    elif [[ -n "$_listVerbose" ]]; then
        : # do nothing
    else
        # Remove final `nmap` performance output line
        _allDevicesStdout="$(echo "$_allDevicesStdout" | trim -b 1)"
    fi

    _allDevicesStdout="$(echo "$_allDevicesStdout" | trim)"

    if echo "$_allDevicesStdout" | egrep -q '\S'; then
        echo "$_allDevicesStdout"
    else
        : # Don't print anything if only whitespace is emitted
    fi

    echo "$_allDevicesStdout"
}


findPids() {
    # TODO Remove PPID from output, i.e. searching for `111` will return both bottom entries
    #   USER  PID  PPID  COMMAND
    #   me    000     1  -bash
    #   me    111   000  setup_project.sh
    #   me    222   111  npm install
    listprocesses "$@" | awk '{ print $2 }'
}

getParentPid() {
    ps -o ppid= ${1:-$$} | trim
}

ancestorProcesses() {
    declare USAGE="[-n|--num-generations <num-generations>] [PID]
    Shows process information for <num-generations>, starting with <PID>.
    PID defaults to BASHPID (or \$\$ if it's undefined, e.g. on Mac's primitive version of Bash).
    "
    declare _numGenerations=
    declare argsArray
    declare -A _ancestorProcessesOptions=(
        ['n|num-generations:,_numGenerations']='Maximum number of processes to find (default: infinity).'
        ['USAGE']="$USAGE"
    )

    parseArgs _ancestorProcessesOptions "$@"
    (( $? )) && return 1

    declare _startingPid="${argsArray[0]}"
    _numGenerations="${_numGenerations:--1}"

    if [[ -z "$_startingPid" ]]; then
        _startingPid="${BASHPID:-$$}"
    fi


    declare _ancestorPids=()
    declare _currentPid="$_startingPid"
    declare _ancestorProcessesHeader="$(listprocesses | head -n 1)"
    # Use `awk` to dynamically determine the number of columns for aligned printing later
    declare _ancestorProcessesHeaderLength="$(echo "$_ancestorProcessesHeader" | awk '{ print NF }')"
    declare _ancestorProcessesDetails="$_ancestorProcessesHeader\n"

    while (( _currentPid != 1 )) && (( _numGenerations != 0 )); do
        _ancestorPids+=("$_currentPid")
        # --cols $_ancestorProcessesHeaderLength
        _ancestorProcessesDetails+="$(
            listprocesses -a "-o pid= $_currentPid" \
            | trim -t 1 \
            | awk '{ $NF=""; print $0 }' # Remove trailing `-o pid` output since it duplicates the PID column. Only needed b/c primitive Mac doesn't support `--pid 123,456,789` format even with Brew's newest Bash v5
        )\n"
        # echo -e "_ancestorProcessesDetails: $_ancestorProcessesDetails"
        _currentPid="$(getParentPid $_currentPid)"
        _numGenerations=$(( _numGenerations - 1 ))
    done

    if (( ${#_ancestorPids[@]} < 1 )); then
        return 1
    fi

    # echo "$_ancestorProcessesHeader" | column -t -c "$_ancestorProcessesHeaderLength"

    # declare _ancestorPid
    # for _ancestorPid in "${_ancestorPids[@]}"; do
    #     echo "_ancestorPid: $_ancestorPid"
    #     # listprocesses -a "-o pid= $_ancestorPid" | trim -t 1 | column -t -c "$_ancestorProcessesHeaderLength"
    # done

    declare _ancestorPidsRegex="$(printf '(%s)|' "${_ancestorPids[@]}" | sed -E 's/.$//')"

    # echo "PID hierarchy (${#_ancestorPids[@]}): ${_ancestorPids[@]}"
    # echo "_ancestorPidsRegex: $_ancestorPidsRegex"

    # `-l columnLength` ensures `column` only formats the entries before the specified column length
    # in `-c` such that entries beyond the length are printed as-is (i.e. not spaced evenly).
    # Except it's not supported on Mac and Brew doesn't provide a GNU version of `column`, so only use
    # it if possible.
    if echo '' | column -l 1 &>/dev/null; then
        echo -e "${_ancestorProcessesDetails[@]}" \
            | column -t -c "$_ancestorProcessesHeaderLength" -l "$_ancestorProcessesHeaderLength"
    else
        echo -e "${_ancestorProcessesDetails[@]}" \
            | column -t -c "$_ancestorProcessesHeaderLength"
    fi
}


getip() {
    declare USAGE="[OPTIONS...]
    Gets all IP addresses for the computer.
    "
    declare _localOnly
    declare _publicOnly
    declare _getipQuietMode
    declare -A _getipOptions=(
        ['l|local,_localOnly']='Only output the local LAN IP address.'
        ['p|public,_publicOnly']='Only output the public IP address (seen by the outside world).'
        ['q|quiet,_getipQuietMode']='Remove all-IP-addresses from output, showing only the local/public IPs.'
        ['?']=
        ['USAGE']="$USAGE"
    )

    parseArgs _getipOptions "$@"
    (( $? )) && return 1


    # Must get default interface (`en0`, `en1`, etc.)
    # See: https://superuser.com/questions/89994/how-can-i-tell-which-network-interface-my-computer-is-using/627581#627581
    declare _ipDefaultNetworkInterface=

    if [[ -f /proc/net/route ]]; then  # Linux
        # Column 7 = Metric - How good the interface is (delay, throughput, hop count, reliability).
        #   Lower number is better. See: https://superuser.com/questions/1167244/interpreting-the-metric-column-in-routing-table/1167248#1167248
        # Column 1 = Interface name.
        # Column 2 = Destination - Not exactly sure, but some sort of IP address mapping. I'm guessing `00000000 == 0.0.0.0`.
        #
        # Thus:
        #   - Get columns 1 and 7 if column 2 is localhost.
        #   - Sort by column 7 in ascending order, so the best network interface is listed first.
        #   - Get only the output line associated with the first (best) interface.
        #   - Only print the interface name.
        _ipDefaultNetworkInterface="$(
            awk '$2 == 00000000 {print $7,$1}' /proc/net/route \
                | sort \
                | head -n 1 \
                | awk '{print $2}'
        )"
    elif isDefined route; then  # Mac
        _ipDefaultNetworkInterface="$(route -n get default | awk '/interface/ {print $2}')"
    fi


    declare _ipAllAddressesIpv4=()  # =($(ifconfig | egrep -o "([0-9]{1,3}\.){3}[0-9]{1,3}"))
    declare _allNetworkInterfaces=($(ifconfig -lu 2>/dev/null))
    declare _networkInterface

    if array.empty _allNetworkInterfaces; then
        # `-lu` is for -List -Up
        # If those options aren't supported, then fallback to manual string parsing
        _allNetworkInterfaces=($(ifconfig | egrep -o '^[^\s:]+'))
    fi

    for _networkInterface in "${_allNetworkInterfaces[@]}"; do
        declare _interfaceInfo="$(ifconfig "$_networkInterface")";

        if echo "$_interfaceInfo" | egrep -q '(status: active)|(flags.*UP.*RUNNING)'; then
            declare _interfaceIpv4="$(echo "$_interfaceInfo" | awk '/inet / {print $2}')"

            if [[ -n "$_interfaceIpv4" ]]; then
                _ipAllAddressesIpv4+=("$_networkInterface: $_interfaceIpv4")
            fi
        fi
    done

    # Output:
    declare _getipNoOptions=
    if [[ -z "${_getipQuietMode}${_localOnly}${_publicOnly}" ]]; then
        _getipNoOptions=true
    fi

    if [[ -n "$_getipNoOptions" ]]; then
        echo "All IPs:"
        declare _interfaceToIpv4
        for _interfaceToIpv4 in "${_ipAllAddressesIpv4[@]}"; do
            echo "$_interfaceToIpv4"
        done
    fi


    declare _ipLocalDefault=

    if isDefined ipconfig; then
        # Get IP using built-in tool
        _ipLocalDefault="$(ipconfig getifaddr "$_ipDefaultNetworkInterface" 2>/dev/null)"
    fi

    if [[ -z "$_ipLocalDefault" ]]; then
        # Get IP manually
        # `inet` entry shows IPv4, `inet6` shows IPv6
        _ipLocalDefault="$(ifconfig "$_ipDefaultNetworkInterface" | awk '/inet / {print $2}')"
    fi

    if [[ -n "$_getipNoOptions" ]]; then
        # Default mode
        echo -e "\nYour local IP (default network interface = $_ipDefaultNetworkInterface):"
        echo "$_ipLocalDefault"
    elif [[ -z "$_publicOnly" ]]; then
        # Quiet mode and local-only mode
        echo "$_ipLocalDefault"
    fi

    if [[ -n "$_getipNoOptions" ]] || [[ -z "$_localOnly" ]]; then
        declare _ipPublic="$(curl -sS ifconfig.me)" # --silent hides download progress details, --show-error for use with --silent

        if [[ -z "${_getipQuietMode}${_publicOnly}" ]]; then
            # Default mode
            echo -e "\nPublic IP:"
        fi

        echo "$_ipPublic"
    fi
}


readEnvFile() {
    # Reads a .env, .properties, etc. file containing `key=value` entries
    # on separate lines.
    # Sets the keys as variables in the current shell.
    declare _envFile="$1"

    # Cannot use `cat file | while read` because pipes create subshells,
    # meaning that writing to a variable stays only in that subshell, not the
    # parent (this script's) shell.
    # Thus, use the file as redirected input instead.
    #
    # Also, use `read -r` to maintain backslashes as-is rather than parse them.
    while IFS='=' read -r key value; do
        case "$key" in
            '#'*)
                # Ignore comments
                ;;
            *)
                eval "$key=$value"
                ;;
        esac
    done < "$_envFile"
}

# ( declare allJavaPaths=($(whereis java)); declare path; for path in "${allJavaPaths[@]}"; do if [[ -d "$path" ]]; then find "$path" -type f -iwholename '*/tools.jar*'; fi; done; )
getEnvEntries() {
    declare USAGE="[OPTIONS...] <grep-options>
    Gets the entry from \`env\`.
    "
    declare _envKeysAndVals
    declare _envSortOutput
    declare argsArray
    declare -A _getEnvEntriesOptions=(
        ['e|keys-and-values,_envKeysAndVals']="Output both key and value for queried results instead of just the value."
        ['s|sort,_envSortOutput']="Sort the resulting query matches."
        [':']=
        ['?']=
        ['USAGE']="$USAGE"
    )

    parseArgs _getEnvEntriesOptions "$@"
    (( $? )) && return 1

    declare _getEnvEntriesGrepOptions=()
    declare _getEnvEntriesQuery=()

    array.slice -r _getEnvEntriesGrepOptions argsArray 0 -1   # all but last arg
    array.slice -r _getEnvEntriesQuery argsArray -1   # only last arg

    _getEnvEntriesQuery="${_getEnvEntriesQuery[0]}"

    declare _getEnvEntriesQueryDelimiter="[^:$([[ -z "$_envKeysAndVals" ]] && echo '=')]+" # Separates PATH and key/val entries, `[^:=]`; Allow `=` if keys are desired, `[^:]`
    declare _getEnvEntriesQuerySuffix='($|:)' # Separates PATH entries and/or the end of an entry

    _getEnvEntriesQuery="${_getEnvEntriesQueryDelimiter}${_getEnvEntriesQuery}${_getEnvEntriesQueryDelimiter}${_getEnvEntriesQuerySuffix}"

    # Note: Nest command inside string/var declaration to preserve newlines/similar whitespaces
    declare _matchingEnvValues="$(env \
        | egrep -o "${_getEnvEntriesGrepOptions[@]}" "${_getEnvEntriesQuery}" \
        | sed -E 's/:$//g' \
        | $([[ -n $_envSortOutput ]] && echo "sort -Vu" || echo "cat")
    )"

    echo -e "$_matchingEnvValues"
}


getAllCrlfFiles() {
    # find [args] -exec [command] "output from find" "necessary `-exec` terminator to show end of command"
    find . -not -type d -exec file "{}" ";" | grep CRLF
}


getAllLinesAfter() {
    # sed -rEgex '[start_line],[end_line]/pattern/ delete_lines_before_including_pattern_match'
    sed -E "1,/$1/ d"
}


getCommandsMatching() {
    # `compgen -c` lists all commands available to bash,
    # regardless of install location or binary vs function vs alias
    compgen -c | grep -E "$1"
}


getVarsByPrefix() {
    declare USAGE="${FUNCNAME[0]} [-r regex] <variable-prefix>
    Prints out all variables matching the specified prefix as well as their values."
    declare _varRegex
    declare -A optsConfig=(
        ['r:,_varRegex']='Regex with which to further fine-tune the match filter.'
        [':']=
        ['USAGE']="$USAGE"
    )
    declare argsArray

    parseArgs optsConfig "$@"
    (( $? )) && return 1

    _varRegex="${_varRegex:-.*}" # Default to matching everything
    declare _varPrefix="${argsArray[0]}"

    declare _varPrefixMatch
    for _varPrefixMatch in $(compgen -v "$_varPrefix"); do
        if (( $(echo "$_varPrefixMatch" | egrep -ci "$_varRegex") > 0 )); then
            echo "$_varPrefixMatch=${!_varPrefixMatch}"
        fi
    done
}


lowercaseExtensions() {
    declare _lowerExtsPath="${1:-.}"

    declare _lowerExtsFile
    for _lowerExtsFile in $(find "$_lowerExtsPath" -type f); do
        declare _lowerExtsFilename="$(basename "$_lowerExtsFile")"
        declare _lowerExtsFilenameExt="$(str.replace -p '*.' '' "$_lowerExtsFilename")" # Could also use pattern removal: "${_lowerExtsFilename##*.}"
        declare _lowerExtsFilenameExtLowercase="$(str.lower "$_lowerExtsFilenameExt")"
        declare _lowerExtsFilenameLowercase="$(str.replace -s "$_lowerExtsFilenameExt" "$_lowerExtsFilenameExtLowercase" "$_lowerExtsFilename")"
        declare _lowerExtsFileLowercase="$(str.replace -s "$_lowerExtsFilename" "$_lowerExtsFilenameLowercase" "$_lowerExtsFile")"

        mv "$_lowerExtsFile" "$_lowerExtsFileLowercase"
        echo "Renamed \"$_lowerExtsFile\" to \"$_lowerExtsFileLowercase\""
    done
}


whereIsVarDefined() (
    declare USAGE="${FUNCNAME[0]} <nameToFind> [\`grep -P\` options]
    Finds where a variable in the user's Bash login shell was defined.
    "
    # Inspired by:
    #   https://unix.stackexchange.com/questions/813/how-to-determine-where-an-environment-variable-came-from/154971#154971
    #   https://unix.stackexchange.com/questions/322817/how-to-find-the-file-where-a-bash-function-is-defined/322887#322887
    # Except you stay in the resulting `bash` shell session rather than returning to your own,
    # and you can't `grep` the output.
    # Adding `-ic 'exit'` to the nested `bash` command causes the resulting shell to exit:
    #   `-c 'exit'` to run the command.
    #   `-i` to ensure that bash finishes loading before exit is called (without `-i`, it exits prematurely).
    #
    # Test with:
    # source ~/.profile; ( for var in {egrep,eegrep,dotfilesDir}; do echo "$var"; whereIsVarDefined "$var"; echo -e "\n-----\n"; done; )

    if [[ "$1" =~ -h ]] || (( $# == 0 )); then
        echo -e "$USAGE" >&2
        return 1
    fi

    declare _varToFind="$1"

    shift

    # Outputs a single word:
    #   'keyword' = language keywords, e.g. `if`
    #   'builtin' = Bash commands that aren't executables, e.g. `declare` or `shopt`
    #   'file' = executables, regardless of native or custom PATH
    #   'alias'
    #   'function'
    #   '' = variable
    declare _varType="$(type -t "$_varToFind")"


    if [[ "$_varType" == 'keyword' || "$_varType" == 'builtin' ]]; then
        echo "$_varType"

        return
    fi


    if [[ "$_varType" == 'file' ]]; then
        abspath "$_varToFind"

        return
    fi


    # If alias/function/variable, then we must debug a new interactive login Bash shell to
    # find the origin and/or where it was overwritten.

    # Delimiter placed after the filename, both at the end of `PS4` line (for aliases/variables)
    # and manually added after function `declare` statements.
    declare _varFileDelimiter='<<>>'
    # Command to run in the debugged Bash shell.
    # Default to getting the definitions of aliases and variables.
    declare _varBashCommand="declare -p $_varToFind"
    # Extra flags to pass to the debugged `bash` command.
    declare _extraBashFlags=

    if [[ "$_varType" == 'function' ]]; then
        # `declare -p` doesn't work for functions.
        # `declare -F` usually only gets the function name, but in a debug shell session, it functions
        # in the same way that `caller` does.
        _varBashCommand="echo \"\$(declare -F $_varToFind)$_varFileDelimiter\""
    else
        # `bash -x` activates debug mode from the initiation of the process, so every single call
        # parsed by Bash is shown (except function definitions and anything defined/found in $PATH
        # instead of sourced files).
        _extraBashFlags='-x'
    fi

    # `shopt -s extdebug` = Activate debug mode where it was called
    # `bash -x` = Activate debug mode for the duration of the shell session.
    # In debug mode, Bash always outputs debug traces to STDERR, but that can be changed with the
    # env var `BASH_XTRACEFD=<number>`.
    # However, outputting the traces to STDOUT (1) causes normal STDOUT by the parent shell (which
    # called this function) to be overwritten, so it doesn't pick up the `declare -p` commands for
    # aliases and variables. That could probably be fixed with manually redirecting the nested bash
    # command defined above to STDOUT, but simply redirecting all STDERR to STDOUT afterwards is
    # easier; it's also more reliable so we don't accidentally pick up calls to the desired variable
    # made in other sourced files.
    (
        PS4="+\${BASH_SOURCE[0]}$_varFileDelimiter " \
        bash -lic $_extraBashFlags "shopt -s extdebug; set -x; $_varBashCommand; set +x; exit;"
    ) 2>&1 \
        | egrep "$@" "$_varToFind" \
        | egrep -o "[^\+ ]*/.*(?=$_varFileDelimiter)" \
        | uniq
    # Grep for the desired variable, filter out the filenames from the debug trace using the
    # specified delimiter (e.g. +++/path/to/some.profile<<>> alias <varName>=<varDefinition>),
    # and then reduce duplicated definitions in the same file via `uniq` (however, leave duplicate
    # definitions in different files so it shows all files that define the variable in order of
    # when they defined it).
)


trapAdd() {
    declare _trapAddHandler="$1"
    shift
    declare _trapAddSignals=("$@")

    declare _trapSignal=

    for _trapSignal in "${_trapAddSignals[@]}"; do
        declare _trapPreviousInfo="$(trap -p "$_trapSignal")"

        # `trap -p` outputs the format:
        #   trap -- 'someHandler' SIG
        # To get only the handler without losing any of the contained info:
        #   Remove only the first instance of `trap -- ` in case there are others within the handler
        #   Remove only the very last instance of SIG
        #       Requires capturing any letters before the specified `_trapSignal` since e.g. `INT` becomes `SIGINT`
        #   Unescape strings since `trap -p` always wraps them in single quotes (e.g. `trap "echo 'hi'" EXIT` --> `trap -- 'echo '\''yo'\''' EXIT`)
        #   Remove superfluous starting/ending `'` from previous `trap` calls
        declare _trapPreviousHandlers="$(
            echo "${_trapPreviousInfo/trap -- /}" \
            | sed -E "s/\s+\S*$_trapSignal$//" \
            | sed -E "s/('|\")\\\\\1\1/\1/g" \
            | sed -E "s/(^')|('$)//g"
        )"

        # Add new `trap` handler after the others, injecting a `; ` in between them if previous handlers exist
        trap "${_trapPreviousHandlers:+$_trapPreviousHandlers; }$_trapAddHandler" "$_trapSignal"
    done
}


getLargestAvailableFd() {
    if [[ -d /dev/fd ]]; then
        # File descriptor dir is defined, so get the number from there.
        # Disable color from `ls` so the ASCII chars representing them aren't included in `grep`.
        # Only get the digits (to exclude classifiers since `-F|--classify` from our custom `ls`
        #   alias can't be disabled once enabled).
        # Add 10 to allow extra FDs to be created in between this command and where it's used.
        echo $(( $(ls --color=never /dev/fd | egrep -o '\d+' | sort -r | head -n 1) + 10 ))

        return
    fi

    # /dev/ dir doesn't have /fd/ so get it manually.
    # Only add 3 instead of 10 b/c `exec` usually chooses an FD that's already much higher than
    # the current highest FD.
    echo $(( $( ( exec {FD}>/dev/null; echo $FD; exec $FD>&-; ) 2>/dev/null ) + 3 ))
}

makeTempPipe() {
    # Refs:
    # https://stackoverflow.com/questions/8297415/in-bash-how-to-find-the-lowest-numbered-unused-file-descriptor/17030546#17030546
    # https://superuser.com/questions/184307/bash-create-anonymous-fifo/633185#633185

    declare USAGE="[OPTIONS...]
    Makes a temporary file for IO, and sets its file descriptor into \`\$FD\` for IO redirection.
    Since outputting to a file descriptor auto-seeks it to the end, it cannot be read from directly;
    to read from it, use \`getFileFromDescriptor \$FD\` to get the temp file's path.
    "

    declare _tmpPipeSignals=()
    declare _tmpPipeNoAppendTraps=
    declare argsArray=
    declare -A _tmpPipeOptions=(
        ['s|signal:,_tmpPipeSignals']="Signals to use for \`trap\` call (defaults to: EXIT QUIT INT TERM)."
        ['t|no-append-traps,_tmpPipeNoAppendTraps']="Prevents preservation of calling parent's trap signals."
        [':']=
        ['USAGE']="$USAGE"
    )

    parseArgs -i _tmpPipeOptions "$@"

    if array.empty _tmpPipeSignals; then
        _tmpPipeSignals+=(EXIT QUIT INT TERM)
    fi


    # `mktemp` - Create a temp file
    declare _tmpPipeFile="$(mktemp)"
    # Putting a string in `exec {var}` sets the lowest available file descriptor to that variable
    exec {FD}<>"$_tmpPipeFile"

    # TODO Find out how to get return value (the following line doesn't work).
    #   Calling parent could use `$FD` or they could use `declare myPipe={ makeTempPipe }`
    #   Note: Must be run in `{ cmd }` to keep FD in same shell, not in subshell, where it'll disappear
    #
    # FD is used in the same way normal FD's are, just add a $ in front of them
    # e.g.
    #   echo hello >&$FD
    #   cat <&$FD
    #   exec $FD>&-
    # echo "$FD"

    # `trap` will ensure the temp file is deleted upon exit.
    #
    # FD will automatically be closed upon exit, so no need to
    # close it manually with `exec "$FD">&-` in this trap.
    #
    # Default to adding new command to existing `trap` calls, but optionally disable it.
    declare _tmpPipeTrapCmd='trapAdd'

    if [[ -n "$_tmpPipeNoAppendTraps" ]]; then
        _tmpPipeTrapCmd='trap'
    fi

    # Ensure this call's `_tmpPipeFile` isn't overwritten by another call to
    # `makeTempPipe` by adding the filename directly into the call rather than
    # the variable name.
    "$_tmpPipeTrapCmd" "rm -rf \"$_tmpPipeFile\" && eval \"exec $FD>&-\"" "${_tmpPipeSignals[@]}"

    echo "$_tmpPipeFile"
}

getFileFromDescriptor() {
    declare _fdToSearch="$1"
    declare _lsofOutputHeaders=(COMMAND PID USER FD TYPE DEVICE SIZE_OFF NODE NAME)

    # Include this process' PID b/c it likely made the FD
    # Note: `$$` within `( someCommand )` actually usually resolves to the parent PID
    # So account for this via `BASHPID` (only supported in Bash@>=4).
    # See: https://stackoverflow.com/questions/21063765/why-is-returning-the-same-id-as-the-parent-process/21063837#21063837
    declare _fdToSearchCurrentPid="${BASHPID:-$$}"
    # Include the parent's as well in case the FD is used in a subshell or script
    declare _fdToSearchParentPid="$(ps -o ppid= "$_fdToSearchCurrentPid")"

    # Get FD info by FD numbers and PIDs
    # `lsof` = LiSt Open Files
    # `-d` = file Descriptor
    # `-a` = And (match multiple criteria)
    # `-p` = Process ID
    #
    # Attempt searching both parent and self PIDs
    declare _fdsOfParentAndSelf="$(lsof -d "$_fdToSearch" -a -p "$_fdToSearchParentPid,$_fdToSearchCurrentPid" 2>/dev/null)"

    if [[ -z "$_fdsOfParentAndSelf" ]]; then
        # Fallback to only self PID if can't search parent (e.g. running this inside a separate script file)
        declare _fdsOfSelf="$(lsof -d "$_fdToSearch" -a -p "$_fdToSearchCurrentPid")"
    fi

    declare _fdsFound="${_fdsOfParentAndSelf:-$_fdsOfSelf}"

    # `| \` must be done instead of `\ [\n] |` since comments exist between the lines
    echo "$_fdsFound" | \
        # truncate multiple spaces into one (allows avoiding the `\S+\s+` regex from below)
        tr -s ' ' | \
        # Get group 9 (NAME)
        cut -d ' ' -f 9 | \
        # Remove header
        grep -v NAME | \
        # Uncomment below and change `cut -f 4,9` to include both FD and file in output
        # | sed -E 's/^([0-9]+)\w/\1/' \
        # Remove duplicates in case multiple processes/FDs point to same file
        sort -u


    # Old way: Manually getting files via regex (just a bit more complicated than the above)
    # # Allows selecting an `lsof` header by index.
    # # array.map/str.repeat combo results in e.g. "^\S+\s+" for "COMMAND" and "^\S+\s+\S+\s+" for "PID"
    # declare _lsofOutputMatchers=()
    # array.map -r _lsofOutputMatchers _lsofOutputHeaders "echo \"^\$(str.repeat '\S+\s+' \$(( key + 1 )) )\""
    #
    # # Match "\S+\s+{n}(searchQuery)"
    # # Thus, index must be "searchItem - 1"
    # declare _fdMatchRegex="${_lsofOutputMatchers[2]}$_fdToSearch"
    # declare _fdFileMatchRegex="${_lsofOutputMatchers[7]}(.*)"
    # declare _fdSearchingParentPid="$$"
    #
    # lsof -d $_fdToSearch -p $_fdSearchingParentPid \
    #     | grep $_fdSearchingParentPid \
    #     | egrep "$_fdMatchRegex" \
    #     | esed "s|$_fdFileMatchRegex|\1|"
}


getBgCmdPid() {
    # Returns the PID for the given job ID
    #
    # Default to last background process
    declare _bgCmdPid="$!"

    if [[ -n "$1" ]]; then
        # Option to get job PID from job ID
        _bgCmdPid="$(jobs -l | egrep "^\[$1\]" | cut -d ' ' -f 2)"
    fi

    echo "$_bgCmdPid"
}

getBgCmdJobId() {
    # Returns the job ID for `fg`/`bg` usage
    #
    # Default to the last background process
    # `jobs` args definitions: https://stackoverflow.com/questions/35026395/bash-what-is-a-jobspec/35026498#35026498
    declare _bgCmdPid="$(jobs -p %+)"

    if [[ -n "$1" ]]; then
        _bgCmdPid="$1"
    fi

    jobs -l | grep "$_bgCmdPid" | cut -d ' ' -f 1 | sed -E 's/[^0-9]//g'
}


_parallel() (
    # TODO - Finish this. This was the starter code that's very incomplete but is a good launchpad
    declare tmpFile="$(mktemp)"
    declare FD=

    exec {FD}<>"$tmpFile"

    closeCmd="eval \"exec $FD>&-\""

    trap "$closeCmd && lah /dev/fd" EXIT QUIT INT TERM

    echo blah >> "$tmpFile"
    lah /dev/fd
    echo "FD: $FD - tmpFile: $tmpFile - FileContents: $(cat "$tmpFile")"
    echo "closeCmd: $closeCmd"
    lah /dev/fd
    echo "tmpFile: $(lah "$tmpFile")"
)
parallel() (
    # See: https://stackoverflow.com/questions/965053/extract-filename-and-extension-in-bash
    declare USAGE="[OPTION]... <cmdStrings>...
    Runs all terminal commands separately in parallel, and returns the total exit code of each of them
    summed together.

    Outputs all STD(OUT|ERR) to the respective receiving pipe as normal.
    "
    declare argsArray
    declare stdin
    declare -A _parallelOptions=(
        ['USAGE']="$USAGE"
    )

    parseArgs _parallelOptions "$@"
    (( $? )) && return 1

    declare _parallelCmds=("${stdin[@]}" "${argsArray[@]}")

    declare _parallelPids=()

    declare _parallelCmd
    for _parallelCmd in "${_parallelCmds[@]}"; do
        echo "COMMAND: $_parallelCmd"
        eval "$_parallelCmd" &

        _parallelPids+=($!)
    done

    declare _parallelSubProcsExitCodesTotal=0

    declare _parallelSubProcPid=
    for _parallelSubProcPid in "${_parallelPids[@]}"; do
        # Wait for each individual PID in order to get its exit code
        wait "$_parallelSubProcPid"

        declare _parallelSubProcExitCode="$?"

        (( _parallelSubProcsExitCodesTotal += $_parallelSubProcExitCode ))
    done

    # return $_parallelSubProcExitCode
    exit $_parallelSubProcExitCode

    declare _parallelSubProcExitCode
    for _parallelSubProcExitCode in "${_parallelPids[@]}"; do
        (( _parallelCmdsExitCodeTotal += $_parallelSubProcExitCode ))
    done

    wait "${_parallelPids[@]}"

    echo "_parallelCmdsExitCodeTotal=$_parallelCmdsExitCodeTotal"

    exit $_parallelCmdsExitCodeTotal


    exit 2 &

    # wait $!
    _parallelPids+=($?)

    exit 7 &

    # wait $!
    _parallelPids+=($?)

    exit 3 &

    # wait $!
    _parallelPids+=($?)

    echo "$(jobs -l)"

    wait

    echo "$(jobs -l)"

    declare exitCodeTotal=0

    declare subProcExitCode=
    for subProcExitCode in "${_parallelPids[@]}"; do
        (( exitCodeTotal += $subProcExitCode ))
    done

    echo "exitCodeTotal=$exitCodeTotal"

    exit $exitCodeTotal
)



zipSizeAfterUnzipped() {
    # See: https://unix.stackexchange.com/questions/229931/how-to-know-how-much-space-an-uncompressed-zip-will-take/229936#229936
    unzip -Zt "$1"
}

zipSizeAfterGzipped() {
    declare USAGE="[OPTIONS...] <path...>
    Outputs the size of the path(s) after gzip-ing them.
    "
    declare _humanReadable
    declare _outputIndividualFiles
    declare argsArray
    declare stdin
    declare -A _zipAfterGzippedOptions=(
        ['r|human-readable,_humanReadable']="Display output gzipped sizes in human-readable format."
        ['f|files,_outputIndividualFiles']="Display individual files' gzipped size along with the directory."
        ['USAGE']="$USAGE"
    )

    parseArgs _zipAfterGzippedOptions "$@"
    (( $? )) && return 1

    declare _dirsToZip=("${stdin[@]}" "${argsArray[@]}")

    if array.empty _dirsToZip; then
        _dirsToZip=('.')
    fi

    declare _zippedIfsOrig="$IFS"
    declare IFS=$'\n'

    declare _zipSizeTotal=0
    # Need to use separate map with string entries/newline separators since arrays aren't
    # acceptable values
    declare -A _zippedDirFileContents=()
    declare -A _zippedDirNameSizeMap=()
    declare -A _zippedFileNameSizeMap=()

    declare _dirToZip
    declare _fileToZip

    for _dirToZip in "${_dirsToZip[@]}"; do
        for _fileToZip in $(find "$_dirToZip" -type f); do
            declare _fileSizeAfterGzipped="$(gzip -c "$_fileToZip" | wc -c)"

            (( _zipSizeTotal += _fileSizeAfterGzipped ))

            _zippedDirNameSizeMap["$_dirToZip"]="$(( _zippedDirNameSizeMap["$_dirToZip"] + _fileSizeAfterGzipped ))"
            _zippedFileNameSizeMap["$_fileToZip"]="$_fileSizeAfterGzipped"
            _zippedDirFileContents["$_dirToZip"]+="$_fileToZip\n"
        done
    done

    declare _zippedDirsSorted=($(printf "%s\n" ${!_zippedDirNameSizeMap[@]} | sort))

    if [[ -z "$_outputIndividualFiles" ]]; then
        for _dirToZip in "${_zippedDirsSorted[@]}"; do
            declare _dirToZipSize="${_zippedDirNameSizeMap["$_dirToZip"]}"

            if [[ -n "$_humanReadable" ]]; then
                _dirToZipSize="$(bytesReadable "$_dirToZipSize")"
            fi

            if (( ${#_zippedDirNameSizeMap[@]} == 1 )); then
                echo "$_dirToZipSize"
            else
                echo "${_dirToZip}: $_dirToZipSize"
            fi
        done
    else
        for _dirToZip in "${_zippedDirsSorted[@]}"; do
            declare _dirToZipSize="${_zippedDirNameSizeMap["$_dirToZip"]}"

            if [[ -n "$_humanReadable" ]]; then
                _dirToZipSize="$(bytesReadable "$_dirToZipSize")"
            fi

            echo "${_dirToZip}: $_dirToZipSize"

            for _fileToZip in $(echo -e "${_zippedDirFileContents["$_dirToZip"]}"); do
                declare _fileToZipSize="${_zippedFileNameSizeMap["$_fileToZip"]}"

                if [[ -n "$_humanReadable" ]]; then
                    _fileToZipSize="$(bytesReadable "$_fileToZipSize")"
                fi

                echo -e "${_fileToZip}: $_fileToZipSize"
            done
        done
    fi

    if (( ${#_zippedDirsSorted[@]} < 2 )); then
        return
    fi

    if [[ -n "$_humanReadable" ]]; then
        _zipSizeTotal="$(bytesReadable "$_zipSizeTotal")"
    fi

    echo "Total: $_zipSizeTotal"
}



# TODO: https://askubuntu.com/questions/442997/how-can-i-convert-audio-from-ogg-to-mp3
# ( IFS=$'\n'; for file in $(find . -iname '*.ogg'); do fullPath="$file"; path=$(echo "$file" | awk '{ print $1 }' | sed -E 's|/[^/]+$||'); file=$(echo "$file" | sed -E 's|(^.*/)([^/]+)\.ogg$|\2|g'); echo "Path: ($path) File: ($file)"; done; )
# Use --parents to make `mv` create nested dirs: https://stackoverflow.com/a/547927/5771107



hashDir() {
    declare USAGE="[OPTIONS...] [path...] [-- \`findIgnoreDirs\` OPTIONS...]
    Hashes directories with SHA-256 since native commands like \`sha256sum\` can only hash files.

    Does so by hashing all files in the directory, sorting them by name, and then
    hashing that final output string.

    Optionally, specify custom \`findIgnoreDirs\` options after a double-hyphen arg, \`--\` in
    order to fine-tune what files count towards the final hash.
    Useful for ignoring .git/node_modules, selectively finding the hash of only a subset of files
    in the directory (e.g. dist/), etc.
    "
    declare _hashDirIncludeFiles
    declare _hashDirIncludeDirs
    declare _hashDirHashesFirst
    declare argsArray
    declare stdin
    declare -A _hashDirOptions=(
        ['f|filenames,_hashDirIncludeFiles']='Include individual file hashes in the output.'
        ['d|directory-names,_hashDirIncludeDirs']='Include top-level directory names in the output.'
        ['h|hashes-first,_hashDirHashesFirst']='Prints hashes before names in output; No effect without `-d` and/or `-f`.'
        ['USAGE']="$USAGE"
    )

    parseArgs _hashDirOptions "$@"
    (( $? )) && return 1

    declare _hashDirNoOptionsPassed=

    if [[ -z "${_hashDirIncludeFiles}${_hashDirIncludeDirs}${_hashDirHashesFirst}" ]]; then
        _hashDirNoOptionsPassed=true
    fi

    # `--` signifies to stop parsing options and forward args as positional ones, usually
    # to an underlying process/command.
    declare _hashDirFindOpts=()
    declare _hashDirFindOptsSeparatorIndex="$(array.indexOf argsArray '--')"

    if [[ -n "$_hashDirFindOptsSeparatorIndex" ]]; then
        # Extract trailing args after the `--` to the `find` options array
        array.slice -r _hashDirFindOpts argsArray $(( _hashDirFindOptsSeparatorIndex + 1 ))
        # Extract leading args before the `--` to the args array for this function
        array.slice -r argsArray argsArray 0 _hashDirFindOptsSeparatorIndex
    fi

    declare _hashDirAllPaths=("${stdin[@]}" "${argsArray[@]}")
    declare _dirHashes=()

    declare _hashDirPath
    for _hashDirPath in "${_hashDirAllPaths[@]}"; do
        declare _fileHashes=()

        # Separate by newline for easier array creation
        declare _origIFS="$IFS"
        declare IFS=$'\n'
        declare _filesToHash=($(findIgnoreDirs -p "$_hashDirPath" "${_hashDirFindOpts[@]}" -type f)) #  2>/dev/null
        IFS="$origIFS"

        declare _fileToHash
        for _fileToHash in "${_filesToHash[@]}"; do
            declare _fileHashAndName="$(sha256sum "$_fileToHash")"

            _fileHashes+=("$_fileHashAndName")
        done

        # Avoid another for-loop by just joining the "hash\tname" entries by newlines
        declare _fileHashesStr="$(array.join -s _fileHashes '\n')"
        # Sort by "version" (i.e. alphanumeric) starting from the 2nd column onward
        # `-k start[,end][options]` means that not specifying an end causes `sort` to continue
        # checking subsequent columns if the previous ones were the same
        declare _fileHashesSortedByFilename="$(echo "$_fileHashesStr" | sort -V -k 2)"
        # Prevent inaccurate hashes due to `echo` appending newlines at the end of the output
        declare _dirHash="$(echo -n "$_fileHashesSortedByFilename" | sha256sum | awk '{ print $1 }')"

        if [[ -n "$_hashDirNoOptionsPassed" ]]; then
            echo "$_dirHash"

            continue
        fi

        if [[ -n "$_hashDirIncludeDirs" ]]; then
            if [[ -z "$_hashDirHashesFirst" ]]; then
                echo -e "$_hashDirPath\t$_dirHash"
            else
                echo -e "$_dirHash\t$_hashDirPath"
            fi
        fi

        if [[ -n "$_hashDirIncludeFiles" ]]; then
            if [[ -z "$_hashDirHashesFirst" ]]; then
                _fileHashesSortedByFilename="$(echo "${_fileHashesSortedByFilename[@]}" | awk '{
                    hash = $1
                    $1 = ""

                    line = sprintf("%s\t%s", $0, hash)
                    gsub(/(^[ \t]+)|([ \t]+$)/, "", line)

                    print(line)
                }')"
            fi

            echo "$_fileHashesSortedByFilename"
        fi
    done
}



_copyCommand=
_pasteCommand=

copy() {
    # Create new `copy` command for writing content to the clipboard.
    # Can be used with both piping `echo "hi" | copy` and with args `copy "hi"`.
    #   Ref: https://stackoverflow.com/questions/5130968/how-can-i-copy-the-output-of-a-command-directly-into-my-clipboard/62517779#62517779
    #
    #
    # Input from `&0` and/or `/dev/stdin` can be piped directly to another command,
    # e.g. what is done in most of the `git.profile` functions.
    #
    # However, to handle entries individually, like how `find` outputs each discovered
    # match one-by-one to `&1`, then a `read` call must be made.
    #
    # This can be done by either:
    #
    # 1) "Parallel"/piping output as it's processed, per-entry, in a loop:
    #       while read inputLine; do
    #           echo "$inputLine"
    #       done
    # 2) "Sequential"/non-piping to collect all input before doing anything:
    #       `readarray -t inputArray`
    #     Where `readarray` == `mapfile`, both of which are array-friendly versions of `read`
    # 3) See below.
    #
    # Both use IFS to determine distinct entries, so something
    # like `echo 'a b' c | myFunc` will read `a b c` as one entry.
    #
    # Note that `stdin=("$(cat -)")` doesn't work b/c it calls `cat` in a subshell,
    # so all IFS-separated entries are now combined into one.
    # We could do something like `eval 'stdin=("$(cat -)")'` to execute the logic in
    # this current shell, but then we run into issues with spaces, newlines, etc.
    # Alternatively, we could use `<<<&0` or something, but that gets even more complicated.
    # Avoid that mess by just using the built-in, more user-friendly, `readX` functions.
    #
    #
    # Alternatively, if supported on your OS (it is on Linux and, surprisingly, Mac), you could use
    # the special `/dev/std(in|out|err)` files to just redirect the content accordingly.
    # See: http://manpages.ubuntu.com/manpages/trusty/en/man1/bash.1.html#:~:text=Bash%20handles%20several%20filenames%20specially%20when%20they%20are%20used%20in%20redirections%2C%20as%20%20described%0A%20%20%20%20%20%20%20in%20the%20following%20table%3A
    declare _toCopyArgs=("$@")
    declare _toCopyStdin=()

    if array.empty _toCopyArgs; then
        readarray -t _toCopyStdin
    fi

    echo -n "${_toCopyStdin[@]}" "${_toCopyArgs[@]}" | $_copyCommand
}

paste() {
    $_pasteCommand
    echo
}

_setClipboardCopyAndPasteCommands() {
    declare _copyPasteError="Error: Cannot find native CLI copy/paste commands for platform [$(os-version -o)].
    In order to copy/paste from the clipboard, \`xclip\` or \`xsel\` are required.
    Please run next command:
        sudo apt-get install xclip"
    declare _printCopyPasteError='echo -e "$_copyPasteError" >&2'

    # Linux OS
    if isLinux; then
        # `paste` is actually a handy tool to merge different files line-by-line
        # where resulting lines are the files' lines joined by <Tab>.
        # First, alias that to a more helpful name so it's not lost, then alias copy/paste.
        alias mergefiles='paste'

        # Try to use one of the third-party utils, or error if not installed.
        if isDefined 'xclip' &>/dev/null; then
            _copyCommand='xclip -sel clipboard'
            _pasteCommand='xclip -sel clipboard -o'
        elif isDefined 'xsel' &>/dev/null; then
            _copyCommand='xsel --clipboard -i'
            _pasteCommand='xsel --clipboard -0'
        else
            eval "$_printCopyPasteError"
        fi
    # Mac OS
    elif isMac; then
        # Use built-in `pb` commands.
        _copyCommand='pbcopy'
        _pasteCommand='pbpaste'
    elif isWindows; then
        echo "TODO - Find copy/paste commands for Windows (git-bash, Linux subsystem, etc.)"
    else
        eval "$_printCopyPasteError"
    fi
} && _setClipboardCopyAndPasteCommands



decodeUri() {
    # See: https://stackoverflow.com/questions/6250698/how-to-decode-url-encoded-string-in-shell
    declare argsArray
    declare stdin
    declare -A _decodeUriOptions=()

    parseArgs _decodeUriOptions "$@"
    (( $? )) && return 1

    declare _uriInput="${stdin[@]} ${argsArray[@]}"

    # `sed`:
    #   `s/+/ /g` to replace all `+` characters with spaces.
    #   `s/%(..)/\x\1/g` to convert from URI-escaped strings to Bash strings (e.g. `%20` to `\x20`).
    # `echo -e` to parse `\x` for its meaning rather than the literal characters.
    echo -e "$(echo "$_uriInput" | sed -E 's/\+/ /g; s/%(..)/\\x\1/g')"
}



dirsize() {
    declare USAGE="[OPTIONS...] <path=./>
    Displays total disk usages of all directories within the given path.

    By default, this shows the apparent file sizes (the size of the file's contents),
    rather their actual space usage on disk (disk blocks used/allocation size, usually
    larger than the file's contents).
    This behavior can be customized (see options below).
    "
    declare _depth
    declare _showFiles
    declare _ignoredPaths
    declare _actualDiskSpaceUsed
    declare argsArray
    declare -A _dirsizeOptions=(
        ['d|depth:,_depth']='Depth of directories to display; defaults to 1 (dirs inside <path>).\nTotal disk usages will be calculated regardless of value.'
        ['f|include-files,_showFiles']='Include files in output.'
        ['i|ignore:,_ignoredPaths']='Path glob(s) to ignore (multiple paths require using multiple flags).'
        ['a|actual,_actualDiskSpaceUsed']='Show the physical/actual/real disk usage (i.e. blocks reserved for the file(s) on disk)'
        ['USAGE']="$USAGE"
    )

    parseArgs _dirsizeOptions "$@"
    (( $? )) && return 1

    if [[ -n "$_showFiles" ]]; then
        echo -e "Directories:"
    fi

    declare _path="${argsArray[0]:-.}"
    _depth="${_depth:-1}"

    if [[ -z "$_actualDiskSpaceUsed" ]]; then
        _actualDiskSpaceUsed="-b"  # `du [-b|--bytes]` means "apparent size" i.e. block size == 1 byte
    else
        _actualDiskSpaceUsed=''
    fi

    declare _ignoredPathsFlags=()
    if ! array.empty _ignoredPaths; then
        if ! array.isArray _ignoredPaths; then
            _ignoredPaths=("$_ignoredPaths")
        fi

        declare _ignoredPath
        for _ignoredPath in "${_ignoredPaths[@]}"; do
            _ignoredPathsFlags+=('--exclude' "$_ignoredPath")
        done
    fi

    # ls -lah has a max size display of 4.0K or 1G, so it doesn't show sizes bigger than that,
    # and doesn't tally up total size of nested directories.
    # du = disk usage
    #   -h human readable
    #   -d [--max-depth] of only this dir
    # sort -reverse -human-numeric-sort - sorts based on size number (taking into account
    #   human-readable sizes like KB, MB, GB, etc.) in descending order
    # Manually add '/' at the end of output to show they are directories
    du -h -d $_depth $_actualDiskSpaceUsed "${_ignoredPathsFlags[@]}" "$_path" | sort -rh | sed -E 's|(.)$|\1/|'

    if [[ -n "$_showFiles" ]]; then
        echo -e "\nFiles:"

        # du can't mix -a (show files) and -d (depth) flags, so run it again for files
        find "$_path" -maxdepth $_depth -type f -print0 | xargs -0 du -h | sort -rh
    fi
}


memusage() {
    # `ps` = process status, gets information about a running process.
    # vsz = Virtual Memory Size: all memory the process can access, including shared memory and shared libraries.
    # rss = Resident Set Size: how much memory allocated to the process (both stack and heap), not including
    #       shared libraries, unless the process is actually using those libraries.
    # TL;DR, RSS is memory the process is using while VSZ is what the process could possibly use
    #
    # ps
    # | grep (column title line and search query)
    # | awk 'change columns 3 and higher to be in MB instead of KB'
    # | sed 'remove double-space from CPU column b/c not sure why it is there'
    ps x -eo pid,%cpu,user,command,vsz,rss | egrep -i "(RSS|$1)" | awk '{
        for (i=2; i<=NF; i++) {
            if ($i~/^[0-9]+$/) {
                $i=$i/1024 "MB";
            }
        }

        print
    }' | sed 's|  %CPU| %CPU|'
}



### Directory traversal ###

reposDir="`dirname "$dotfilesDir"`"  # use `dirname` instead of `realpath` to preserve symlinks/~ in path
repos() {
    # Path is relative to repositories directory.
    # Read all args via `$@` instead of `$1` in case spaces aren't escaped.
    #   `"$@"` collects all args into one string, even those separated by spaces (which would usually
    #   be split into separate lines internally by bash/function arg interpretation).
    declare nestedPath="$@"
    # Note: Manually parsing strings via something like
    # absPath="`echo "$reposDir/$nestedPath" | tr '\n' ' ' | sed -E 's:([^\\]) (.):\1\\ \2:g'`"
    # to (1) replace newline-separated args, and (2) replace the now-one-line `my path/` with `my\ path/`
    # doesn't work/help/add anything new because bash double-quote strings automatically remove
    # backslashes (spaces don't need escaping in strings).
    declare absPath="$reposDir/$nestedPath"

    cd "$absPath"
}
_autocompleteRepos() {
    # TODO - try `builtin cd "${some-combo-of-reposDir-and-COMP_WORDS}"` and/or find out how to use
    #   the autocompletion from builtins (`builtin only runs the built-in command, not necessarily
    #   its assigned `complete` function)
    declare requestedRelativePath="${COMP_WORDS[@]:1}"
    declare requestedAbsPath="$reposDir/$requestedRelativePath"

    # Note: `sed` seems to handle backslashes differently depending on where and how it's used.
    #   If on root-level, these work:
    #     echo "$var" | sed -E 's:\\ : :g'
    #     echo "$var" | sed -E "s:\\\ : :g"
    #   If nested inside another call, these work:
    #     newVar="`echo "$var" | sed -E 's:\\\ : :g'`"   # note the triple \ even in single-quotes
    #     newVar="$(echo "$var" | sed -E "s:\\\ : :g")"  # note the similarity to root-level, but requires $() instead of back-ticks
    #     (haven't tested for the double-quote inside back-ticks)

    # `find` is stupid and won't resolve escaped paths.
    # But at the same time, the suggestion autocomplete system will fail if the path isn't escaped
    # (see COMPREPLY note below).
    # Thus, unescape them only for `find` but otherwise leave them untouched.
    requestedAbsPath="`echo "$requestedAbsPath" | sed -E 's:\\\ : :g'`"

    # `find` will also fail if `$requestedAbsPath` doesn't exist, e.g. when the user presses <Tab> on
    # a partial directory name.
    # Thus, if the dir doesn't exist, then default to searching in the parent dir.
    if [[ -d "$requestedAbsPath" ]]; then
        declare resolvedRelativePath="$requestedRelativePath"
        declare resolvedAbsPath="$requestedAbsPath"
    else
        declare resolvedRelativePath="`dirname "$requestedRelativePath"`"
        declare resolvedAbsPath="`dirname "$requestedAbsPath"`"
    fi

    declare dirOptions="`find -L "$resolvedAbsPath" -maxdepth 1 -type d`"  # -L follows symlinks. Necessary b/c we're searching `/repo/dir` and not `/repo/dir/`

    # Filter resulting directory options to include suggestions for only dirs that include the
    # string the user searched for.
    # Include partial dir names by using `$requestedAbsPath` instead of `$resolvedAbsPath`.
    # Note: Quote `$dirOptions` so that newlines are preserved.
    #   If it weren't quoted, all results would be on one line (`find` doesn't escape spaces in its
    #   results), causing any dirs that have spaces in their names to be impossible to parse separately.
    dirOptions="`echo "$dirOptions" | grep "$requestedAbsPath"`"

    # `sed "...d"` command is less user friendly than `s` in that to use any delimiter other
    # than `/`, it must be escaped.
    # e.g. `sed '/x/d'` --> `sed '\:x:d'`

    # Format dir options to be human readable.
    #   Remove the preceding repository-directory path.
    #   Remove any lines that are blank or only contain `/`.
    #   Replace double slashes with single slashes.
    #   Add a trailing slash to the end of dir options.
    dirOptions="`echo "$dirOptions" | sed -E "s:$reposDir/?::; \:^/?$:d; s://:/:; s:^/::; s:([^/])$:\1/:"`"

    if ! [[ -z "$requestedRelativePath" ]]; then
        # Remove the entry that is exactly the same as the path already prefilled in the shell
        dirOptions="`echo "$dirOptions" | egrep -v "$requestedRelativePath$"`"
    fi

    # Escape spaces in paths. See note above.
    dirOptions="$(echo "$dirOptions" | sed -E "s:([^\\]) (.):\1\\\ \2:g")"

    # Standard compgen logic, i.e.
    # `COMPREPLY=($(compgen -W "$dirOptions"))`
    # doesn't work when we manually escape strings because it takes the spaces out.
    # However, leaving unescaped spaces in causes the suggestions list to only autocomplete
    # the last word in the shell, resulting in a valid path's last word being replaced by
    # other random text (in our case, it's `find "$(dirname path)"` since we search the parent
    # if the child isn't found).
    # Thus, in order of causation:
    #   - The spaces have to be escaped
    #   - We can't use compgen
    #   - We generate our own word array
    #   - Word array needs to be split by newlines instead of spaces (done via IFS)
    # Note: Using quotes around paths was attempted, but that failed as well (also caused a worse
    # user experience b/c spaces being autocompleted in the shell wouldn't automatically be removed
    # when trying to go into a nested directory).
    declare IFS=$'\n'
    COMPREPLY=($dirOptions)

    return
}
# TODO Look up `-X filterpat` for filename expansion
#   https://www.gnu.org/savannah-checkouts/gnu/bash/manual/bash.html#Programmable-Completion-Builtins
# `compopt` might help for removing nested directory prefixes

# Don't split options by space; split by newline instead b/c paths could include spaces in them.
# The easiest way to handle this would have been `-o filenames`, except that caused the issues above
# where the last word in a directory with spaces would be swapped out unexpectedly.
complete -F _autocompleteRepos -o nospace 'repos'
