mount() {
    sshfs dpowell1@dash1w102m3.etrade.com:/dashboard ~/dashboard/
}

unmount() {
    umount -f ~/dashboard/
}

remount() {
    unmount
    mount
}

usage() {
    echo "Usage: mount_dashboard.sh [m/mount | u/unmount | r/remount]"
    exit
}

case "$1" in
    "m"|"mount")
        mount;;
    "u"|"unmount")
        unmount;;
    "r"|"remount")
        remount;;
    "")
        mount;;
    *)
        usage;;
esac