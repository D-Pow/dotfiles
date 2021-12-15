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
```

## Linux

```bash
/home/<user>/.WebStorm2019.1/config/eval
/home/<user>/.WebStorm2019.1/config/options/other.xml
```