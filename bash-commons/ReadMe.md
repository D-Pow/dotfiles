# Bash docs

## [All docs](https://www.gnu.org/software/bash/manual/bash.html)

* More details and examples at https://tldp.org/LDP/abs/html/index.html

## [`complete`](https://www.gnu.org/software/bash/manual/html_node/Programmable-Completion-Builtins.html)

* https://www.oreilly.com/library/view/bash-quick-reference/0596527764/re18.html

## [`compgen`](https://www.gnu.org/software/bash/manual/html_node/Programmable-Completion-Builtins.html)

* [`complete`/`compgen` options](https://unix.stackexchange.com/questions/151118/understand-compgen-builtin-command/151120#151120)
* [`complete` vs `compgen`](https://unix.stackexchange.com/questions/250262/how-to-use-bashs-complete-or-compgen-c-command-option)
* [`complete` example](https://www.gnu.org/software/bash/manual/html_node/A-Programmable-Completion-Example.html)

## Processes

* `$$` = Current process' PID.
* `$!` = PID of most recent background process.
    - See [StackOverflow post about them](https://stackoverflow.com/questions/13671750/what-does-mean-or-in-bash/13671768#13671768).

## [IO/redirection](https://www.gnu.org/software/bash/manual/bash.html#Redirections)

* Great explanation: https://unix.stackexchange.com/questions/159513/what-are-the-shells-control-and-redirection-operators/159514#159514
* `0` = stdin
* `1` = stdout
* `2` = stderr
* `src > dest` = Output redirect (overwrites anything in dest). Use `>>` to append.
* `dest < src` = Input redirect.
* `dest < <(srcCommand)` = Input redirect + bash process substitution.
    - Runs `srcCommand` and use the output as input to `dest`.
    - Examples:
        + https://stackoverflow.com/questions/6541109/send-string-to-stdin/61973974#61973974
* `dest <(srcCommand)` = Input redirect + bash process substitution as a file.
    - Runs `srcCommand`, converts it to a file (Idk if temp file or just an Inode in RAM), and then uses that "file" as input to `dest`.
    - Examples:
        + Check if a file has changed using a previous hash: `diff my-file.hash <(sha256sum my-file.txt)`
* `src >(destCommand)` = Output redirect + bash process substitution.
    - Runs `src` and use the output as input to `destCommand`.
    - Examples:
        + https://stackoverflow.com/questions/13804965/how-to-tee-to-stderr/20553986#20553986
* `&` = File descriptor.
    - A reference to a file/location (by the number it's assigned to) for reading/writing.
    - Most commonly used to redirect `STD(IN|OUT|ERR)`.
    - Can also be used to create new input/output addresses for ease of access (see `<>` below).
* `(src) >&(destFD)` = Output `src` to the `destFD` file descriptor.
    - `>(&FD | filename)` defaults left-hand to `1`/`STDOUT`.
* `(dest) <&(srcFD)` = Use `srcFD` as input to the `dest` command.
    - `<(&FD | filename)` defaults left-hand to `0`/`STDIN`.
    - Note: Redirections are executed in order.
        + `cmd >&2 2>err.log` doesn't send stdout to `err.log`.
        + `cmd 2>err.log >&2` does.
    - Examples:
        + `cmd 2>&1` = output stderr to stdout (useful for e.g. printing errors to the console instead of a log file when running an application)
        + `cat err.log >&2` = output the contents of err.log to stderr
        + `cmd &>/dev/null` = output all FDs (e.g. both stdout and stderr) to /dev/null
* `(FD)<> (srcAndDest)` = Use `srcAndDest` for reading and writing instead of only one.
    - Assigns `srcAndDest` to new `FD` file descriptor for use in other scripts.
    - `FD` number must be > 2 since 0-2 are defined above.
    - Creates new `srcAndDest` file if it doesn't already exist (everything is a file in Unix!!).
* `>&-` = Close file descriptor.
    - Note: You cannot append to FD when using read+write mode, `<>`.
    - Instead, you can instead open the file in append-only mode: `exec (newFD)>>my.file`
    - Examples:
        + https://tldp.org/LDP/abs/html/io-redirection.html
* Example - Let's implement the append operator, `echo 'some text' >> my.file`:
    ```bash
    # `eval`: Output 'stdoutText' to FD 1 (stdout) and 'stderrText' to FD 2 (stderr)
    # Entire `eval` content is redirected: stdout goes to stderr (printed to the console), stderr is saved to err.log
    eval 'echo stdoutText; echo stderrText >&2' >&2 2>err.log
    exec 5<> err.log    # Assign err.log to FD address number 5
    cat <&5 >/dev/null  # Forwards err.log content to `cat` but doesn't print to the console (FD 1 redirected to /dev/null so output is silenced).
                        # In our case, it's used to skip to the end of the file so new content is appended to the end.
    echo '# High priority error' >&5   # Add custom note that the last error in err.log is of high priority.
    exec 5>&-   # Close err.log (FD 5) to prevent further reading/writing
    ```

## [Here Documents/Here Strings](https://www.gnu.org/software/bash/manual/bash.html#Here-Documents)

* Generally, you'll want to use here documents (`<<-`) instead of here strings (`<<<`) unless you **want your command on one line**.
* Add a hyphen (`<<-`) to strip leading Tab characters (NOT spaces) so you can indent as you please.
* Use an extra input redirection instead of a hyphen (`<<<`) for single-line input strings.
* To quote `DelimiterText` or not to quote:
    - Quoting will make the containing string (`here-document`) be read literally, i.e. variables/commands from the containing parent function block won't be parsed.
    - Not quoting will allow parent variables/commands to be expanded before passing to `cmd`.
* The closing `DelimiterText` CANNOT have leading spaces before it; See: https://stackoverflow.com/questions/19986541/error-when-using-a-bash-here-doc-unexpected-end-of-file
* e.g.
    ```bash
    cmd <<- DelimiterText
        # here-document
        text
        $var
        $(command)
    DelimiterText
    ```

## [Special keywords](https://www.gnu.org/software/bash/manual/bash.html#Bash-Variables)

## [String manipulation](https://tldp.org/LDP/abs/html/string-manipulation.html)

## [Pattern matching](https://www.gnu.org/savannah-checkouts/gnu/bash/manual/bash.html#Pattern-Matching) and [Bash's primitive regex](https://tldp.org/LDP/abs/html/regexp.html)

* `*(pattern)` = Zero or more occurrences.
* `?(pattern)` = Zero or one occurrence.
* `+(pattern)` = One or more occurrences.
* `@(pattern)` = One occurrence.
* `!(pattern)` = Anything except one of the given patterns.

Examples:

* `**/*.@(test|spec).[tj]s?(x)` - Finds all JS, JSX, TS, and TSX files with a sub-extension of "test" or "spec" at any level of directory nesting.

## [Variable manipulation](https://www.gnu.org/software/bash/manual/bash.html#Shell-Parameter-Expansion)

* Includes stuff like slicing, string replacement, substitutions, etc.
* Can be applied to all variables: arrays, strings, files, etc.

### [Parameter substitutions](https://pubs.opengroup.org/onlinepubs/9699919799/utilities/V3_chap02.html#tag_18_06_02)

Where:

* "null" = `declare var=` or `declare var=''`
* "unset" = `var` never instantiated or if no value set, e.g. `declare var`

| Expansion       |  Set && !null    |    Set & null        |      Unset
| --------------- | ---------------- | -------------------- | -----------------
| `${var:-word}`  |  return `$var`   |    return `word`     |   return `word`
| `${var-word}`   |  return `$var`   |    return `null`     |   return `word`
| `${var:+word}`  |  return `word`   |    return `null`     |   return `null`
| `${var+word}`   |  return `word`   |    return `word`     |   return `null`
| `${var:=word}`  |  return `$var`   |    assign `word`     |   assign `word`
| `${var=word}`   |  return `$var`   |    return `null`     |   assign `word`
| `${var:?word}`  |  return `$var`   |  error `word`; exit  |  error `word`; exit
| `${var?word}`   |  return `$var`   |    return `null`     |  error `word`; exit


Examples:

* `${var:-word}` - Result is 'word' if `var` is (unset|null), otherwise it's `${var}`
* `${var+word}` - Result is nothing if `var` is (unset), otherwise `word`

### [String substitution](https://tldp.org/LDP/abs/html/parameter-substitution.html)

* `${var#Pattern}` - Remove from `$var` the shortest part of `$Pattern` that matches the **front** end of `$var`.
    - `${var/#Pattern/Replacement}` - Replace in `$var` any match of `$Pattern` from the **front** end of `$var`.
* `${var##Pattern}` - Remove from `$var` the longest part of `$Pattern` that matches the **front** end of `$var`.
* `${var%Pattern}` - Remove from `$var` the shortest part of `$Pattern` that matches the **back** end of `$var`.
* `${var%%Pattern}` - Remove from `$var` the longest part of `$Pattern` that matches the **back** end of `$var`.
    - `${var/%Pattern/Replacement}` - Replace in `$var` any match of `$Pattern` from the **back** end of `$var`.






<!--
_testParameterExpansion() {
    declare varDeclarations=('' 'declare var' 'declare var=' 'declare var=""' 'declare var="hello"')
    declare tests=(
        '${var:-word}'
        '${var-word}'
        '${var:+word}'
        '${var+word}'
        '${var:=word}'
        '${var=word}'
        '${var:?word}'
        '${var?word}'
    )

    for (( i=0; i < "${#varDeclarations[@]}"; i++ )); do
    # for varDeclaration in "${varDeclarations[@]}"; do
        declare varDeclaration="${varDeclarations[i]}"
        unset var
        eval "$varDeclaration"
        echo "New var declaration: $varDeclaration - var: `
            declare -p var 2>/dev/null || echo 'unset'
        `" # show how $var was created with `declare -p`, but don't show an error if $var was never declared

        for (( j=0; j < "${#tests[@]}"; j++ )); do
        # for test in "${tests[@]}"; do
            declare test="${tests[j]}"
            (
                echo "Test $test: ${var:+(current var: $var)}"
                eval "echo output: $test" # Has to be done in `eval "echo $test"` b/c param-expansion
                                          # only works in commands, e.g. `echo "${...}"` or `myVar=${...}`
                                          # so something like `eval "${...}"` throws an error
                echo "var value after expansion: $var"
                (( j != (${#tests[@]} - 1) )) && echo # print separators between tests, but not after last test
            )
        done

        (( i != (${#varDeclarations[@]} - 1) )) && echo -e '\n\n' # print extra separators only between $var declarations
    done
} && _testParameterExpansion
-->
