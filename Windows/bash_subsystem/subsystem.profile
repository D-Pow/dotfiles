export rootdir='C:/Users/djp93/AppData/Local/Packages/CanonicalGroupLimited.UbuntuonWindows_79rhkp1fndgsc/LocalState/rootfs'
export homedir="$rootdir/home/dpow"

# alias sourceprofile='chmod a+rx /home/dpow/.profile && source /home/dpow/.profile'
alias subl='cmd subl'

alias listupdate='sudo apt update && sudo apt list --upgradable'

topath () {
    readlink -m "$1"
}

towindowspath () {
    path=$(topath "$1")
    # sed -e (execute script that uses regex) interpretation:
    #     1st -e: replace anything that isn't '/mnt/c' with '$rootdir/'
    #         Used for the case that path isn't in /mnt/c
    #         in which case just append $rootdir to the beginning
    #     2nd -e: replace '/mnt/c' with 'C:'
    #         Used for the case that path is in /mnt/c
    #         in which case, we're in a Windows directory, so no need to append $rootdir
    #         so we simply need to change '/mnt/c' with 'C:'
    echo $path | sed -e "/^\\/mnt\\/c/! s|/|$rootdir/|" -e "s|/mnt/c|C:|"
}

cmd () {
    # For some reason, flags aren't picked up in $@, $2, etc. so just parse out the command
    commandToRun="$1"
    rest=${@/$commandToRun/""}
    /mnt/c/Windows/System32/cmd.exe "/C" "$commandToRun" $rest
}

clip () {
    echo "$1" | cmd clip
}
