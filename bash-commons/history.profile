### .bash_history improvements ###
# Variables below can be found in keywords link above.
# History commands: https://www.gnu.org/software/bash/manual/html_node/Bash-History-Builtins.html
###

# Remove duplicate commands.
HISTCONTROL=ignoredups:erasedups

# Increase number of commands to remember.
HISTSIZE=1000

# Increase number of lines to allow in the file - important for multiline commands.
HISTFILESIZE=$(( $HISTSIZE * 10 ))

# Append to .bash_history instead of overwriting it.
shopt -s histappend

# Option to allow history across all active shell sessions immediately rather than only on session close.
# Put in function so it can be (de-)activated in other .profile files.
ORIG_PROMPT_COMMAND="$PROMPT_COMMAND"
bashHistoryImmediatelyAvailableAcrossShellSessions() {
    # See:
    #   https://unix.stackexchange.com/questions/1288/preserve-bash-history-in-multiple-terminal-windows
    #   https://unix.stackexchange.com/questions/18212/bash-history-ignoredups-and-erasedups-setting-conflict-with-common-history
    local usage="(De-)activate .bash_history being written to immediately after running commands instead of only on shell termination.

    Usage: ${FUNCNAME[0]} [-a|-d]

    Options:
        -a | Activate immediate command appending.
        -d | Deactivate immediate command appending."

    local activate

    while getopts ":adh" opt; do
        case "$opt" in
            a)
                activate=true
                ;;
            d)
                activate=false
                ;;
            *)
                echo "$usage"
                return
                ;;
        esac
    done

    if [[ "$activate" = 'true' ]]; then
        # See: https://unix.stackexchange.com/questions/18212/bash-history-ignoredups-and-erasedups-setting-conflict-with-common-history/18443#18443
        # If this causes issues with history not being saved correctly, try: https://unix.stackexchange.com/questions/18212/bash-history-ignoredups-and-erasedups-setting-conflict-with-common-history/556267#556267
        PROMPT_COMMAND="history -n; history -w; history -c; history -r; $PROMPT_COMMAND"
    else
        PROMPT_COMMAND="$ORIG_PROMPT_COMMAND"
    fi
}
