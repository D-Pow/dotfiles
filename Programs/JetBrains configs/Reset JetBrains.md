## Windows

Delete:

* `HKEY_CURRENT_USER/Software/JavaSoft/Prefs/jetbrains`
    - (Might have to be repeated for an HKEY_USERS user, but prob not)
* `$HOME/.PyCharm/eval`
* `$HOME/.PyCharm/options/options.xml`

## Mac

```bash
cd ~/Library/Preferences/
rm -rf jetbrains.*.plist com.jetbrains.*.plist
cd ~/Library/Preferences/WebStorm[version]/
rm -rf ./eval/WebStorm*  ./options/options.xml

# Clear cache in RAM of .plist files -- force reloading them so you don't have
# to restart the computer.
#
# If modified and the files are still present:
#   defaults read <filename>.plist
# If deleted (like we're doing above)
#   defaults delete <filename>.plist
#
# See:
#   - https://stackoverflow.com/questions/51153974/how-to-force-reload-preference-plist-for-an-app-in-os-x/51168058#51168058
defaults delete jetbrains.*.plist com.jetbrains.*.plist
```

## Linux

```bash
/home/<user>/.WebStorm2019.1/config/eval
/home/<user>/.WebStorm2019.1/config/options/other.xml
```
