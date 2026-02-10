# [Karabiner Mac Key Mapper](https://karabiner-elements.pqrs.org/)

The best option out there for re-mapping keyboard/mouse buttons to custom functions.

* **Don't map keys in System Preferences**, only use Karabiner since it takes care of e.g. Ctrl --> Command remapping itself.
* Simply copy this folder to the `~/.config/` directory after installing Karabiner.
    - Then, activate them by clicking "Add predefined rule" and "Enable all" at the end of the title of the rule-set(s) copied to the `assets/` directory.
* Make sure that `Terminal -> Preferences -> Profiles --> 'Use Option as Meta key'` is checked, otherwise the Option/Ctrl keys won't work for e.g. moving cursor by word.
* **Disable `Spaces` in Mac keyboard shortcuts**
    - `System Preferences --> Keyboard --> Shortcuts --> Mission Control --> Move (left|right) a space`.
        + Required to allow `Ctrl+(left|right)_arrow` work in JetBrains.
* **Disable `Screenshots` in Mac keyboard shortcuts**
* **Disable period on double space and smart quotes/dashes**
    - System Settings -> Keyboard -> Input Sources (Edit)
        + Uncheck "Add period with double-space" and "Use smart quotes and dashes"
* Make hidden files always visible
    - Run `defaults write com.apple.finder AppleShowAllFiles TRUE`
        + Otherwise, you have to press `Command + Shift + .` to show them
* Fix Screenshot showing draggable rectangle instead of drawable crosshairs
    - Open Screenshot -> Options -> Uncheck "Remember last selection" option.
    - Press `Command+Shift+4` shortcut to force crosshairs (`Command+Shift+5` opens Screenshot app).
    - From now on, Screenshot will use that method.
* **Other**
    - `JetBrains --> Keymap --> Activate Next Window --> Command+Tilde`
* [Rules defined first take precedence over rules defined later](https://karabiner-elements.pqrs.org/docs/json/complex-modifications-manipulator-evaluation-priority/)
* [Manual](https://karabiner-elements.pqrs.org/docs/manual/configuration/)


## Simple Configurations (single key maps)

* [Manual](https://karabiner-elements.pqrs.org/docs/manual/configuration/configure-simple-modifications/)


## Complex Configurations (key combos)

* Get the bundle identifier for an app: `osascript -e 'id of app "MyApp"'`
* [Manual](https://karabiner-elements.pqrs.org/docs/manual/configuration/configure-complex-modifications/)
* [Sample complex configurations](https://ke-complex-modifications.pqrs.org/)
* [Helpful tool for generating/verifying syntax of complex rules](https://genesy.github.io/karabiner-complex-rules-generator/)



# Special Keyboard Keys

Use [USB Overdrive](https://www.usboverdrive.com/) to find/map special keys not found by Karabiner.

Note: USB Overdrive can't find Web Home/Forward/Back on Mac OS Big Sur (11.4).


## Other

Move windows in Terminal via:

```bash
osascript -e 'tell application "System Events" to tell (first process whose frontmost is true)
    tell first window
        set {x, y} to position
        set {w, h} to size
        set position to {x - 1920, y}
    end tell

    -- Optional maximize afterwards
    key down 63  -- fn key
    keystroke "f" using {control down}
    key up 63
end tell'
```

where `x - 1920` to move left/plus to move right (assumes 1920px-wide monitor) and key 63 is the Fn key (Mac doesn't allow this in curly braces like it does for Ctrl, Command, etc.).

In order to make this one-line, you can't add semicolons like you can in Bash. Insted, split each line into a new `-e` arg.
