# Git

* Make `ignorePathsInGit()` work.
    - This doesn't work, not sure why:
        + `cd linux/ && gd -- ':/' ':(exclude)bash-commons/git.profile'`

# General

* Rename `bash-X.profile` to just `X.profile`
* Move common.profile notes to separate `bash-notes.profile` or similar
* Move string manipulation code to new `strings.profile` file
    - Starter content:
    - https://stackoverflow.com/questions/55623092/parsing-a-string-with-quotes-in-getopts
    - This:

        ```bash
        # Gotten from: https://stackoverflow.com/questions/23356779/how-can-i-store-the-find-command-results-as-an-array-in-bash/54561526
        declare IFS=$'\n'
        declare res=($allEntriesWithTrailingSlashOnDirsDirs)
        array.toString -ld '\n' res
        ```

# Mac enhancements

* Allow moving windows between displays.
    - Starter: https://apple.stackexchange.com/a/361168

# Sublime

* Figure out how to make file-browser side bar show file/code structure instead.
* js-beautify PR for:
    - Arrays of objects - putting each object brace on new line
    - Put array entries on new lines
        + Optionally, by line length or number of entries
    - Spaces between inline object/array braces

# `repos`

* Might be able to replace manual escaping with [printf %q](https://stackoverflow.com/questions/589149/bash-script-to-cd-to-directory-with-spaces-in-pathname)
* Replace `$HOME` with `~`, but only in final output
    - Starter:
        ```bash
        echo "`pwd | sed -E "s:(^$HOME)(.*):~\2:g"`"
        ```
    - `~` will still need to be expanded for actual processing and can only be used in commands like `cd` if it's not a literal string (e.g. `cd '~/Documents/'` fails).
* Allow symlinks to `~/my-dir/` to translate to `~/my-dir/` instead of `/some/path/my-dir/`
* Remove preceding `dotfiles/Programs/` from suggestions, e.g. `dotfiles/Programs/Sublime/`
    - Starter: https://stackoverflow.com/questions/15978504/add-text-at-the-end-of-each-line
* Ref:
    - https://unix.stackexchange.com/questions/62400/bash-tab-completion-expands-into-home-when-it-didnt-before
    - https://superuser.com/questions/442765/why-does-bash-tab-expand-a-tilde-when-i-am-completing-a-vim-file-name#comment512884_442767
    - https://stackoverflow.com/questions/12240940/echoing-a-tilde-to-a-file-without-expanding-it-in-bash
    - https://stackoverflow.com/questions/10036255/is-there-a-good-way-to-replace-home-directory-with-tilde-in-bash
    - https://stackoverflow.com/questions/2172352/in-bash-how-can-i-check-if-a-string-begins-with-some-value

# Arrays

* Make new util scripts for array handling, e.g.
    - `arr-from-string $str $delimiter`
    - `arr-to-string` can be improved (re: why I didn't use it in `array.filter()`)
* Starter resources:
    - https://stackoverflow.com/questions/15691942/print-array-elements-on-separate-lines-in-bash
    - https://stackoverflow.com/questions/8467424/echo-newline-in-bash-prints-literal-n
    - https://superuser.com/questions/461981/how-do-i-convert-a-bash-array-variable-to-a-string-delimited-with-newlines/462400
    - https://stackoverflow.com/questions/14525296/how-do-i-check-if-variable-is-an-array
    - https://unix.stackexchange.com/questions/227662/how-to-rename-multiple-files-using-find
    - [slicing](https://stackoverflow.com/questions/1335815/how-to-slice-an-array-in-bash)
* Once done, remove `/linux/Bash notes.txt`

# New - Change mac address

* Mac: https://eshop.macsales.com/blog/43777-tech-101-spoofing-a-mac-address-in-macos-high-sierra/?utm_source=affiliate&utm_campaign=cj&cjevent=974ffbd5dc1a11eb817702230a1c0e13
    - Get all mac addresses on network: `arp -a`
    - Get your mac address: `ifconfig [en0|network-device] ether`
    - Change it: `sudo ifconfig <device> ether XXX`
        + Might have to run the command [multiple times](https://www.reddit.com/r/mac/comments/jzjzoc/changing_mac_address_on_2020_mbp_w_macos_big_sur/)
        + Or, maybe shutting it down/turning it back on would do the trick (see Linux below)
* Linux: https://www.linuxquestions.org/questions/linux-networking-3/ubuntu-how-to-change-mac-address-with-ifconfig-647323/
* Storing previous mac address for resetting back to normal: https://stackoverflow.com/questions/9904980/variable-in-bash-script-that-keeps-it-value-from-the-last-time-running
