export rootdir='C:/Users/djp93/AppData/Local/Packages/CanonicalGroupLimited.UbuntuonWindows_79rhkp1fndgsc/LocalState/rootfs'
export homedir="$rootdir/home/dpow"

# alias sourceprofile='chmod a+rx /home/dpow/.profile && source /home/dpow/.profile'

alias listupdate='sudo apt update && sudo apt list --upgradable'

topath() {
    readlink -m "$1"
}

towindowspath() {
    path=$(topath "$1")
    # sed -e (execute script that uses regex) interpretation:
    #     1st -e: replace anything that isn't '/mnt/c' or '/mnt/d' with '$rootdir/'.
    #         Used for the case that path isn't in /mnt/c or /mnt/d
    #         in which case just append $rootdir to the beginning.
    #         `!` == "cases that don't match"
    #     2nd -e: replace '/mnt/X' with 'X:'.
    #         Used for the case that path is in a Windows directory,
    #         e.g. /mnt/c or /mnt/d, so no need to append $rootdir.
    #         Simply change '/mnt/c' with 'C:', likewise for 'D:'
    echo $path | sed -e "/^\\/mnt\\/[dc]/! s|/|$rootdir/|" -e "s|/mnt/c|C:|" -e "s|/mnt/d|D:|"
}

cmd() {
    # For some reason, flags aren't picked up in $@, $2, etc. so just parse out the command
    commandToRun="$1"
    rest=${@/$commandToRun/""}
    /mnt/c/Windows/System32/cmd.exe "/C" "$commandToRun" $rest
}

subl() {
    cmd subl $(towindowspath $1)
}

clip() {
    echo "$1" | cmd clip
}
