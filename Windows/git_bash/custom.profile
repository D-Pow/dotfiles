export wslProfile="$dotfilesDir/Windows/wsl/custom.profile"

source "$wslProfile"

# alias subl='/c/Program\ Files/Sublime\ Text\ 3/subl'

export FORCE_COLOR=1

export rootdir='C:/Users/djp93'
export homedir="$rootdir"

# Note: Run `ln -s /path/to/jdkFolder /path/to/jdk-active` to make this work
# Also, add `%JAVA_PATH%` above the `/path/to/Oracle/Java/javapath` entry in PATH
export JAVA_HOME='C:/Program Files/Java/jdk-active'
export JAVA_PATH="$JAVA_HOME/bin"


workDir='/g/My Drive/Work'
alias todo="subl '$workDir/ToDo.md'"

alias gh="/c/Program\ Files/GitHub\ CLI/gh.exe"



# TODO make the command below work
# subl -n `towindowspath '/mnt/d/file with spaces.txt' /home/file`
_testargs() {
    declare argArray=()

    # $@ is all args
    # Wrapping "$@" in double quotes preserves args that have spaces in them
    for i in "$@"; do
        parsedPath=`towindowspath "$i"`
        argArray+=("$parsedPath")
    done

    subl -n "${argArray[@]}"
}
