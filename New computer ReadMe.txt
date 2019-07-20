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
        