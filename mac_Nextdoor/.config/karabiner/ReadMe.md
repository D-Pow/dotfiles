# [Karabiner Mac Key Mapper](https://karabiner-elements.pqrs.org/)

The best option out there for re-mapping keyboard/mouse buttons to custom functions.

* **Don't map keys in System Preferences**, only use Karabiner since it takes care of e.g. Ctrl --> Command remapping itself.
* Simply copy this folder to the `~/.config/` directory after installing Karabiner.
* Make sure that `Terminal -> Preferences -> Profiles --> 'Use Option as Meta key'` is checked, otherwise the Option/Ctrl keys won't work for e.g. moving cursor by word.
* **Disable `Spaces` in Mac keyboard shortcuts**
    - `System Preferences --> Keyboard --> Shortcuts --> Mission Control --> Move (left|right) a space`.
    - Required to allow `Ctrl+(left|right)_arrow` work in JetBrains.
* [Rules defined first take precedence over rules defined later](https://karabiner-elements.pqrs.org/docs/json/complex-modifications-manipulator-evaluation-priority/)
* [Manual](https://karabiner-elements.pqrs.org/docs/manual/configuration/)


## Simple Configurations (single key maps)

* [Manual](https://karabiner-elements.pqrs.org/docs/manual/configuration/configure-simple-modifications/)


## Complex Configurations (key combos)

* [Manual](https://karabiner-elements.pqrs.org/docs/manual/configuration/configure-complex-modifications/)
* [Sample complex configurations](https://ke-complex-modifications.pqrs.org/)
* [Helpful tool for generating/verifying syntax of complex rules](https://genesy.github.io/karabiner-complex-rules-generator/)



# Special Keyboard Keys

Use [USB Overdrive](https://www.usboverdrive.com/) to find/map special keys not found by Karabiner.

Note: USB Overdrive can't find Web Home/Forward/Back on Mac OS Big Sur (11.4).
