### Bash docs ###
# Special keywords: https://www.gnu.org/software/bash/manual/html_node/Bash-Variables.html
# String manipulation: https://tldp.org/LDP/abs/html/string-manipulation.html
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

source "$(thisDir)/bash-history.profile"
source "$(thisDir)/bash-arrays.profile"
source "$(thisDir)/bash-command-enhancements.profile"
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
