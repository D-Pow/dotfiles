# Linux Panels (i.e. Taskbars)

Each monitor has its own panel, panel settings, and panel applets.

## Fixing Linux not showing windows only on that monitor in its panel

After some OS version upgrade, Linux stopped automatically choosing to only show windows that are present on a given monitor on that monitor's panel. As such, many attempts with `Cobi window list`, `Grouped window list`, etc. panel applets were attempted, and their respective configs added to the [applet-configs](./applet-configs) directory.

The real fix was inspired by [this Mint-forums post](https://forums.linuxmint.com/viewtopic.php?t=303636) which essentially said to:

* Disable:
    - `CobiWindowList`
    - `Grouped window list`
    - `Windows Quick List`
    - `Workspace switcher`
    - `XApp Status Applet`
* Add `Window list` to each monitor's panel (this is the **main** fix).
* Enable `Window list` with settings:
    - `Show windows from all workspaces`: false
* Quality of life improvements (optional):
    - Drag the open-windows section of the panel to the left in "Panel edit mode" if needed since it defaults to the right side.
    - Add `Calendar` to the external monitors' panels.
