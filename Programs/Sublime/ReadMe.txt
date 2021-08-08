Note: download the Windows portable version of 3143 (when the build function actually scrolled
appropriately) at: https://download.sublimetext.com/Sublime%20Text%20Build%203143%20x64.zip

Part A - Copy Data folder to Sublime install location

Add right-click "Open with Sublime"
Files:
    regedit: HKEY_CLASSES_ROOT/*/shell
    Create key named "sublime" (name is actually arbitrary)
        Set default data to "Open with Sublime Text"
    Add new Expandable String value to "sublime" (under default data): "Icon"
        Data = path + ",0"
        e.g. Data = `C:\Program Files (x86)\Sublime Text 3\sublime_text.exe,0`
    Create key named "command"
        Set default data to path: `C:\Program Files (x86)\Sublime Text 3\sublime_text.exe "%1"`
Folders:
    (Right-click *on* folder)
    regedit: HKEY_CLASSES_ROOT/Folder/shell
        Same as above, with files
    (Right-click *in* folder)
    regedit: HKEY_CLASSES_ROOT/Directory/Background/shell
        Same as above, with files, except the command needs to be changed from "%1" to "%V"

Linux:
    Put the sublime.(desktop|nemo_action) files in the locations specified in the `linux/.local/` sub-directory of this repository.

Part B - Install helpful things and change settings manually
 a) Install PackageControl, then PackageResourceViewer (ctrl+shift+p -> install package).
    Install packages listed in the Preferences file via PackageControl.
    PackageControl at https://packagecontrol.io

 b) Copy the Preferences file to the correct location

 c) Add following key mappings:
    [
        { "keys": ["ctrl+tab"], "command": "next_view" },
        { "keys": ["ctrl+shift+tab"], "command": "prev_view" },
        { "keys": ["ctrl+shift+o"], "command": "prompt_open_folder"}
    ]

 d) Add following mousemap settings:
    [
        // Prevent changing font size with ctrl+scroll wheel
        { "button": "scroll_down", "modifiers": ["ctrl"], "command": "null" },
        { "button": "scroll_up", "modifiers": ["ctrl"], "command": "null" }
    ]

 e) Using PackageResourceViewer, open JavaC build system and change the build line to:
    "shell_cmd": "javac \"$file\" && java \"$file_base_name\"",
    Which will run the java program after building it


For Japanese on Linux:
    Run in Sublime Packages: git clone https://github.com/yasuyuky/SublimeMozcInput.git
    Add in key bindings: { "keys": ["ctrl+`"], "command": "toggle_mozc"},
