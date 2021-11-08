### Bash docs ###
#
# All docs: https://www.gnu.org/software/bash/manual/bash.html
# `complete`: https://www.gnu.org/software/bash/manual/html_node/Programmable-Completion-Builtins.html
#             https://www.oreilly.com/library/view/bash-quick-reference/0596527764/re18.html
# `compgen`: https://unix.stackexchange.com/questions/151118/understand-compgen-builtin-command/151120#151120
#
# IO/redirection: https://www.gnu.org/software/bash/manual/bash.html#Redirections
#   Great explanation: https://unix.stackexchange.com/questions/159513/what-are-the-shells-control-and-redirection-operators/159514#159514
#   0 = stdin
#   1 = stdout
#   2 = stderr
#   (src) > (dest) = Output redirect (overwrites anything in dest). Use `>>` to append.
#   (dest) < (src) = Input redirect.
#   & = File descriptor.
#       A reference to a file/location (by the number it's assigned to) for reading/writing.
#       Most commonly used to redirect std(in|out|err).
#       Can also be used to create new in-/output addresses for ease of access (see `<>` below).
#   (src) >&(destFD) = Output `src` to the `destFD` file descriptor.
#   (dest) <&(srcFD) = Use `srcFD` as input to the `dest` command.
#   Note: `>(&FD | filename)` defaults left-hand to 1. `<(&FD | filename)` defaults left-hand to 0.
#   Note: Redirections are executed in order. e.g. `cmd >&2 2>err.log` doesn't send stdout to err.log, but `cmd 2>err.log >&2` does.
#       e.g.
#       cmd 2>&1  # output stderr to stdout (useful for e.g. printing errors to the console instead of a log file when running an application)
#       cat err.log >&2  # output the contents of err.log to stderr
#       cmd &>/dev/null  # output all FDs (e.g. both stdout and stderr) to /dev/null
#   (FD)<> (srcAndDest) = Use `srcAndDest` for reading and writing instead of only one.
#       Assigns `srcAndDest` to new `FD` file descriptor for use in other scripts.
#       `FD` number must be > 2 since 0-2 are defined above.
#       Creates new `srcAndDest` file if it doesn't already exist (everything is a file in Unix!!).
#   >&- = Close file descriptor.
#   Note: You cannot append to FD when using read+write mode, `<>`.
#       But you can instead open the file in append-only mode: `exec (newFD)>>my.file`
#   Good examples of these can be found at: https://tldp.org/LDP/abs/html/io-redirection.html
#   e.g. Let's implement the append operator, `echo 'some text' >> my.file`:
#       # `eval`: Output 'stdoutText' to FD 1 (stdout) and 'stderrText' to FD 2 (stderr)
#       # Entire `eval` content is redirected: stdout goes to stderr (printed to the console), stderr is saved to err.log
#       eval 'echo stdoutText; echo stderrText >&2' >&2 2>err.log
#       exec 5<> err.log    # Assign err.log to FD address number 5
#       cat <&5 >/dev/null  # Forwards err.log content to `cat` but doesn't print to the console (FD 1 redirected to /dev/null so output is silenced).
#                           # In our case, it's used to skip to the end of the file so new content is appended to the end.
#       echo '# High priority error' >&5   # Add custom note that the last error in err.log is of high priority.
#       exec 5>&-   # Close err.log (FD 5) to prevent further reading/writing
#
# Special keywords: https://www.gnu.org/software/bash/manual/bash.html#Bash-Variables
#
# String manipulation: https://tldp.org/LDP/abs/html/string-manipulation.html
#
# Variable manipulation: https://www.gnu.org/software/bash/manual/bash.html#Shell-Parameter-Expansion
#   Includes stuff like slicing, string replacement, substitutions, etc.
#   Can be applied to all variables: arrays, strings, files, etc.
#
#   Parameter substitutions (See: https://pubs.opengroup.org/onlinepubs/9699919799/utilities/V3_chap02.html#tag_18_06_02)
#     Where:
#     "unset" = `var` never instantiated or if no value set, i.e. `declare var`
#     "null" = `declare var=` or `declare var=''`
#
#    Expansion    |  Set && !null  |    Set & null      |      Unset
#   ${var:-word}  |  return $var   |    return word     |   return word
#   ${var-word}   |  return $var   |    return null     |   return word
#   ${var:+word}  |  return word   |    return null     |   return null
#   ${var+word}   |  return word   |    return word     |   return null
#   ${var:=word}  |  return $var   |    assign word     |   assign word
#   ${var=word}   |  return $var   |    return null     |   assign word
#   ${var:?word}  |  return $var   |  error word, exit  |  error word, exit
#   ${var?word}   |  return $var   |    return null     |  error word, exit
#
#   e.g.
#       ${var:-word} - Result is 'word' if `var` is (unset|null), otherwise it's `${var}`
#       ${var+word} - Result is nothing if `var` is (unset), otherwise `word`

source "$(thisDir)/parse-args.profile"
source "$(thisDir)/history.profile"
source "$(thisDir)/strings.profile"
source "$(thisDir)/arrays.profile"
source "$(thisDir)/command-enhancements.profile"
source "$(thisDir)/os-utils.profile"
source "$(thisDir)/git.profile"
source "$(thisDir)/programs.profile"

# _testParameterExpansion() {
#     declare varDeclarations=('' 'declare var' 'declare var=' 'declare var=""' 'declare var="hello"')
#     declare tests=(
#         '${var:-word}'
#         '${var-word}'
#         '${var:+word}'
#         '${var+word}'
#         '${var:=word}'
#         '${var=word}'
#         '${var:?word}'
#         '${var?word}'
#     )
#
#     for (( i=0; i < "${#varDeclarations[@]}"; i++ )); do
#     # for varDeclaration in "${varDeclarations[@]}"; do
#         declare varDeclaration="${varDeclarations[i]}"
#         unset var
#         eval "$varDeclaration"
#         echo "New var declaration: $varDeclaration - var: `
#             declare -p var 2>/dev/null || echo 'unset'
#         `" # show how $var was created with `declare -p`, but don't show an error if $var was never declared
#
#         for (( j=0; j < "${#tests[@]}"; j++ )); do
#         # for test in "${tests[@]}"; do
#             declare test="${tests[j]}"
#             (
#                 echo "Test $test: ${var:+(current var: $var)}"
#                 eval "echo output: $test" # Has to be done in `eval "echo $test"` b/c param-expansion
#                                           # only works in commands, e.g. `echo "${...}"` or `myVar=${...}`
#                                           # so something like `eval "${...}"` throws an error
#                 echo "var value after expansion: $var"
#                 (( j != (${#tests[@]} - 1) )) && echo # print separators between tests, but not after last test
#             )
#         done
#
#         (( i != (${#varDeclarations[@]} - 1) )) && echo -e '\n\n' # print extra separators only between $var declarations
#     done
# } && _testParameterExpansion
