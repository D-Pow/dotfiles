# Dconf Settings

`dconf` is used to configure settings from the terminal for both the OS and most applications, particularly settings that are usually accessed via GUIs/top menu bars. This also includes the `Settings` GUI for the OS.

<details>
    <summary>
        Filtering out lines that were only reordered and not changed
    </summary>
    <br />

Find lines changed in Git that are weren't simply reordered via `git diff my-file.conf > diff.git`, opening it in your text editor, doing a regex search for `^[\+-].*$)(?=[\s\S]*\n[\+-]\1\n)`, and then manually deleting all lines with the matched text.

This can't be done in Sublime Text b/c the look-ahead will either not capture the second matching text or it will capture everything in between the first and second matching texts.

However, this can be done in JavaScript (optionally copying to the clipboard) via:

```javascript
copy(
s.split('\n')
    .filter(line =>
        !line.match(/^\s+$/)
        && ![...s.matchAll(
            /(?<=\n)[\+-]([^\n]*(?=\n))(?=[\s\S]*\n[\+-]\1[\n|$])/g
        )]
            .filter(([ wholeStr, matchGroup ]) => !wholeStr.match(/^[\+-]$/))
            .map(([ wholeStr, matchGroup ]) => matchGroup)
            .includes(line.substring(1))
    ).join('\n')
)
```

</details>

## Usage

* Note: **DO NOT USE SUDO**.
* Import
    ```
    dconf load /org/path/to/settings/or/program/ < my_settings.conf
    ```
* Export:
    ```
    dconf dump /org/path/to/settings/or/program/ > my_settings.conf
    ```
* Write new value:
    ```
    dconf write /path/to/settings/key value
    ```
* Delete ([ref](https://askubuntu.com/questions/457175/how-to-remove-element-from-gsettings-array-in-script), [related](https://askubuntu.com/questions/1090244/dconf-database-how-to-remove-duplicate-triplicates)):
    ```
    dconf write /path/to/settings/key '@as []'
    ```

## Settings Paths

* Terminal: `/org/gnome/terminal/`
* Cinnamon settings: `/org/cinnamon/`. Includes:
    - Look-and-feel: `/desktop/`
        + High-level/non-specific display details: `/interface/`
            * Clock display, keyboard layout flags, etc.
        + Keyboard
            * Shortcuts: `/keybindings/`
                - For sound/media keys:
                    + [Setting for Spotify only](https://askubuntu.com/questions/1105363/spotify-keyboard-controls-not-working)
                    + (Not working) [terminal command to control audio](https://askubuntu.com/questions/235126/simulate-media-keys-in-terminal/235181#235181), [only play](https://askubuntu.com/questions/389438/trigger-play-pause-event/389452#389452)
                    + [All XF86 keyboard symbols](https://wiki.linuxquestions.org/wiki/XF86_keyboard_symbols)
                    + [All xdotool key codes](https://gitlab.com/cunidev/gestures/-/wikis/xdotool-list-of-key-codes)
                    + [All `dbus-send` services](https://unix.stackexchange.com/questions/46301/a-list-of-available-d-bus-services)
                    + [Maybe try `pactl`](https://forums.linuxmint.com/viewtopic.php?t=247650) or [`pulseaudio`](https://forums.linuxmint.com/viewtopic.php?t=345838)
            * Layouts: `/a11y/keyboard/`
        + Mouse: `/a11y/mouse/`
        + Workspaces: `/wm/preferences/`
            * Set to 1 to remove them completely
    - Windows: `/muffin/`
        + Settings in the actual "Windows" section of the Settings GUI.
        + Stuff like what the title bar does, the buttons on the right-hand side of the title bar, etc.
        + Note: `draggable-border-width` changes how much space you have from the border for the resize-mouse to appear. It's not exposed as an option in the Windows settings GUI so it must be set manually. It [defaults to 10 px](https://github.com/linuxmint/cinnamon/issues/9341#issuecomment-636417578).
    - Sounds: `/sounds/`
        + Mostly just custom sound remappings
    - Other: `/settings-daemon/`
        + Power options: `/plugins/power/`
        + Peripherals (plugged-in devices): `/peripherals/`
            * Touchpad
            * External mouse
            * Keyboard --> Typing
