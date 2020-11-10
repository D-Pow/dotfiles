In addTo.etc.fstab, everything in that line is correct and follows the instructions
at <https://www.howtogeek.com/howto/35807/how-to-harmonize-your-dual-boot-setup-for-windows-and-ubuntu/>,
but adds the additional dmask and fmask to prevent the storage NTFS partition
from being executable by default.
*Note: you MUST change the UUID of the storage drive and make sure that you
actually follow the instructions at the website above so you don't miss something.
Will look almost exactly like what's seen in addTo.etc.fstab.txt (note the intentional Xmasks, Xid, and permission entries)

.sqliterc belongs in home (%userprofile%) directory of Windows

~In Windows Registry:
Open command prompt anywhere
    In BOTH HKEY_CLASSES_ROOT\Directory\shell (for clicking *on* folder) and
            HKEY_CLASSES_ROOT\Directory\Background\shell (for clicking *in* folder):
    Add new key, "CommandPrompt", with data=`Open Command Prompt Here`
    Make new key for CommandPrompt, titled "command" with data=`cmd.exe /s /k pushd "%V"`
        for /Background/shell or `cmd.exe /k cd %1` for /Directory/shell
    Delete the "Extended" value inside HKEY_CLASSES_ROOT\Directory\shell\cmd

Also, add sublime to context menu (see Sublime folder's ReadMe)

You might also want to add "Take ownership" to avoid Windows' stupid "you do not
    have permission for this action." This is in the Windows bookmarks.

open_chrome* belongs in Windows only. Put the shortcut on the desktop.
    You might need to keep deleting and re-creating the keyboard shortcut
    before the shortcut actually works

For LaTeX (TexLive), run the following commands:
    tlmgr init-usertree
    sudo tlmgr update --all
If that fails, you'll have to switch to the old repo (tlmgr not supported in new one):
    tlmgr option repository ftp://tug.org/historic/systems/texlive/2015/tlnet-final
Use sudo for installing things

In Linux, after installing Mozc and IBus (for Japanese input):
    Mozc settings -> Keymap style -> Customize
    Repeat for Direct Input, Composition, and Precomposition:
        Ctrl ` --> Set input mode to Hiragana
        Ctrl 1 --> Set input mode to full-width Katakana

Power options: disable wake timers and (multimedia-> when sharing media-> allow the computer to sleep) to prevent a program from keeping computer from sleeping

Disk check disabled

Disable hybrid sleep to activate hibernate functionality

Remove unnecessary programs at startup

Prevent easy user switching
    HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System
        New DWORD (32-bit) value
        Name: HideFastUserSwitching
        Data: 1

Programs to install:
    Programs from google drive
    // clink (command prompt autocompletion), git bash using MinTTY is better to use as default terminal
    7zip
    BitDefender
    KeyTweak (remaps keyboard keys)
    Linux subsystem
    Chrome
    Discord
    Steam; To copy games:
        * Install Steam
        * Copy userdata/ and steamapps/ folders to new location
    Epic Games; To copy games: (see https://www.gamingpcbuilder.com/how-to-copy-fortnite-without-redownloading/)
        * Install Epic Games
        * Start download of game
        * Cancel (not pause) game after install is >= 1%
        * Quit Epic Games
        * Copy game files over
        * Reopen Epic Games
        * Click "Resume" -> will now verify files instead of re-downloading them
    Git
    Microsoft Office
    Spotify
    VLC (video player)
    Java/Python/Node (nvm)/IDEs/Postman/SQLite
    LaTeX (try to find a portable version)
    Japanese
    Windscribe
    iTunes
    Gimp 2
    wireshark

If dual-booting, convert the disk from MBR (Master Boot Record) to GPT (GUID):
    1. Install Linux first so Grub is accessible.
    2. Change BIOS to boot using UEFI instead of Legacy.
    3. If the Linux install didn't automatically convert the disk to GPT:
        i. Use MBR2GPT in Windows to convert it: https://docs.microsoft.com/en-us/windows/deployment/mbr-to-gpt
        ii. MBR2GPT prefers to be run in the Windows Preinstallation Environment rather than in a booted OS. It's possible to run in the OS, but you could run into issues, e.g. the system recovery being messed up.

For Python-IDLE right-click menu:
Regedit as administrator
HKEY_CLASSES_ROOT\.py\shell --> (make the following keys:)
Edit with IDLE 3.5 --> command --> "C:\Python3\pythonw.exe" "C:\Python3\Lib\idlelib\idle.pyw" -e "%1"
Edit with IDLE 2.7 --> command --> "C:\Python27\pythonw.exe" "C:\Python27\Lib\idlelib\idle.pyw" -e "%1"


If running into issues with GRUB after modifying boot partitions (e.g. deleting/moving partitions you can boot from):
    1. Boot into live Linux USB.
    2. Mount the "Linux filesystem" drive in the USB instance
        `sudo fdisk -l`
        `sudo blkid`
        Get the /dev/sdXX of "Linux Filesystem"
        `sudo mount /dev/sdXX /mnt` to mount that partition into /mnt/ directory
    3. Run "Boot repair" (in start menu) or `boot-repair` (in terminal).
        Advanced options
        Uncheck "Secure Boot" (secure boot was disabled above)
        Uncheck "Repair Windows boot loader" (Windows data should be totally fine, only GRUB is messed up)
    4. Reboot into Linux on hard drive and re-run GrubCustomizer to customize as desired.
