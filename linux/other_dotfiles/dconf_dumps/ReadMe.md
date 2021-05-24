# Dconf Settings

`dconf` is used to configure settings from the terminal for both the OS and most applications, particularly settings that are usually accessed via GUIs/top menu bars. This also includes the `Settings` GUI for the OS.

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

## Settings Paths

* Terminal: `/org/gnome/terminal/`
* Cinnamon settings: `/org/cinnamon/`. Includes:
    - Look-and-feel: `/desktop/`
        + High-level/non-specific display details: `/interface/`
            * Clock display, keyboard layout flags, etc.
        + Keyboard
            * Shortcuts: `/keybindings/`
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
