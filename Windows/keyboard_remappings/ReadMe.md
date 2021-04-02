## How to activate script on startup

Copied from https://www.autohotkey.com/docs/FAQ.htm#Startup.

There are several ways to make a script (or any program) launch automatically every time you start your PC. The easiest is to place a shortcut to the script in the Startup folder:

1. Find the script file, select it, and press `Ctrl+C`.
2. Press `Win+R` to open the Run dialog, then enter `shell:startup` and click OK or `Enter`. This will open the Startup folder for the current user. To instead open the folder for all users, enter `shell:common startup` (however, in that case you must be an administrator to proceed).
3. Right click inside the window, and click `"Paste Shortcut"`. The shortcut to the script should now be in the Startup folder.

## Other info

* Possible way to check keyboard device ID to decide if right Ctrl should be context menu (right click) or normal right Ctrl (i.e. if on native keyboard or external one):
    - [System](https://autohotkey.com/board/topic/38015-ahkhid-an-ahk-implementation-of-the-hid-functions/)
        + [Script from above: AHKHID.ahk](https://raw.githubusercontent.com/jleb/AHKHID/master/AHKHID.ahk)
    - [Remapping key only for external keyboard](https://www.autohotkey.com/boards/viewtopic.php?f=5&t=11896)
    - [Detect USB keyboard](https://autohotkey.com/board/topic/113250-detect-usb-keypad/)
        + [Similar thread](https://autohotkey.com/board/topic/8231-usb-device-connecteddisconnected-notification/://autohotkey.com/board/topic/8231-usb-device-connecteddisconnected-notification/page-2?&#entry168746)
* Mapping keys via registry:
    - Computer\HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\AppKey\
        + 7 is home key
        + 1 is browser back key
        + 2 is browser forward key
* Possible AutoHotKey keylogger script:
    - `Hotkey, % [color=red]"~"[/color] Chr(A_Index+96),SomeLabel`
