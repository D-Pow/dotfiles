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

* Terminal
    - `/org/gnome/terminal/`
* Cinnamon desktop settings
    - `/org/cinnamon/desktop/`
    - Includes:
        + Look-and-feel
            * Interface (`/interface/`) - clock display, keyboard layout flags, etc.
        + Keyboard
            * Shortcuts (`/keybindings/`)
            * Layouts (`/a11y/keyboard/`)
        + Mouse
            * `/a11y/mouse/`
        + Workspaces (set to 1 to remove them)
            * `/wm/preferences/`
