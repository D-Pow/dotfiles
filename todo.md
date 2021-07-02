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
    - `arr-to-string $arr $delimiter`
    - `arr-length $arr`
* Starter resources:
    - https://stackoverflow.com/questions/15691942/print-array-elements-on-separate-lines-in-bash
    - https://stackoverflow.com/questions/8467424/echo-newline-in-bash-prints-literal-n
    - https://superuser.com/questions/461981/how-do-i-convert-a-bash-array-variable-to-a-string-delimited-with-newlines/462400
    - https://stackoverflow.com/questions/14525296/how-do-i-check-if-variable-is-an-array
    - https://unix.stackexchange.com/questions/227662/how-to-rename-multiple-files-using-find
    - [slicing](https://stackoverflow.com/questions/1335815/how-to-slice-an-array-in-bash)
* Once done, remove `/linux/Bash notes.txt`
