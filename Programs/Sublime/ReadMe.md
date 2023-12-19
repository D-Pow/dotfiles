# Part A - Make Sublime more accessible to your OS

Note: Until The [Windows -> Settings -> Zoom (125%) build-output-scroll bug](https://github.com/sublimehq/sublime_text/issues/2291) is fixed, Windows requires ST3 version 3143: https://download.sublimetext.com/Sublime%20Text%20Build%203143%20x64.zip

ST4 might fix this.

## Copy Data folder to Sublime install location

## Add right-click "Open with Sublime"

### Windows

* Files:
    - regedit: `HKEY_CLASSES_ROOT/*/shell`
    - Create key named `sublime` (name is actually arbitrary)
        + Set default data to `Open with Sublime Text`
    - Add new Expandable String value to `sublime` (under default data): `Icon`
        + Data: `path + ",0"`
        + e.g. Data = `C:\Program Files (x86)\Sublime Text 3\sublime_text.exe,0`
    - Create key named `command`
        + Set default data to path: `C:\Program Files (x86)\Sublime Text 3\sublime_text.exe "%1"`
* Folders:
    - (Right-click *on* folder)
        + regedit: `HKEY_CLASSES_ROOT/Folder/shell`
        + Same as above, with files
    - (Right-click *in* folder)
        + regedit: `HKEY_CLASSES_ROOT/Directory/Background/shell`
        + Same as above, with files, except the command needs to be changed from "%1" to "%V"

### Linux

* Put the sublime.(desktop|nemo_action) files in the locations specified in the `linux/.local/` sub-directory of this repository.

# Part B - Install helpful things and change settings manually

* Install PackageControl, then PackageResourceViewer (ctrl+shift+p -> install package).
    - Install packages listed in the Preferences file via [PackageControl](https://packagecontrol.io).
* Copy the Preferences file to the correct location
* Settings/key-mappings files need to be renamed to match your OS.
* For Japanese on Linux:
    - Run in Sublime Packages: `git clone https://github.com/yasuyuky/SublimeMozcInput.git`
    - Add in key bindings: ```{ "keys": ["ctrl+`"], "command": "toggle_mozc"},```


## Remove "Please buy a license" Pop-up

```bash
(
    declare _sublPath="$(which subl || which subl.exe)"
    cp "$_sublPath" "${_sublPath}.bak"
    sed -i 's/\x80\x78\x05\x00\x0f\x94\xc1/\xc6\x40\x05\x01\x48\x85\xc9/g' "$_sublPath"
)
```

[Source](https://gist.github.com/skoqaq/3f3e8f28e23c881143cef9cf49d821ff)
