# User stuff
JAVA_HOME="/usr/java"
GRADLE_HOME="/opt/gradle"
export JAVA_HOME
export GRADLE_HOME
export PATH="$JAVA_HOME/bin:$GRADLE_HOME/bin:$HOME/.local/bin:$PATH"

alias python3=python3.8

# Change directory colors in `ls`
# LS_COLORS="${LS_COLORS}di=01;35"
# export $LS_COLORS

# [green]\username[white]:[teal]\working_directory[white]$[space]
export PS1="\[\033[01;32m\]\u\[\033[00m\]:\[\033[00m\]\[\033[01;34m\]\w\[\033[00m\]\$ "

alias ls='ls -Fh --color'
alias lah='ls -Flah --color'

alias egrep='grep -P --exclude-dir={node_modules,.git,.idea,lcov-report} --color=auto'

alias listupdate='sudo apt update && sudo apt list --upgradable'

# systemctl commands:
#   status              =  shows service status
#   start               =  start a service
#   stop                =  stop a service
#   restart             =  restart a service
#   enable              =  enable a service to start at boot
#   disable             =  disable a service from starting at boot
#   list-units          =  show service names (i.e. names used for above commands)
#   list-unit-files     =  show service files themselves (i.e. what files are actually running when service starts)
# Unit entries' details:
#   avahi-daemon is used for personal computers (not servers) so they can scan for other devices on the network (printers, computers, etc.)
#   docker.socket is used for listening to Docker commands (unrelated to Docker's server, so doesn't open a port itself)
alias liststartupservices='sudo systemctl list-unit-files | grep enabled | sort'

alias open='xdg-open'

alias scan='savscan -all -rec -f -archive'
alias sophosUpdate='sudo /opt/sophos-av/bin/savupdate && /opt/sophos-av/bin/savdstatus --version'

alias apachestart='systemctl start apache2'
alias apachestop='systemctl stop apache2'
alias apachestatus='systemctl status apache2'

# Terminal key-bindings
# Can't do 'Ctrl+C' for copy
gsettings set org.gnome.Terminal.Legacy.Keybindings:/org/gnome/terminal/legacy/keybindings/ new-tab '<Primary>T'
gsettings set org.gnome.Terminal.Legacy.Keybindings:/org/gnome/terminal/legacy/keybindings/ new-window '<Primary>N'
gsettings set org.gnome.Terminal.Legacy.Keybindings:/org/gnome/terminal/legacy/keybindings/ close-tab '<Primary>W'
gsettings set org.gnome.Terminal.Legacy.Keybindings:/org/gnome/terminal/legacy/keybindings/ next-tab '<Primary>Tab'
gsettings set org.gnome.Terminal.Legacy.Keybindings:/org/gnome/terminal/legacy/keybindings/ prev-tab '<Primary><Shift>Tab'
gsettings set org.gnome.Terminal.Legacy.Keybindings:/org/gnome/terminal/legacy/keybindings/ paste '<Primary>V'
gsettings set org.gnome.Terminal.Legacy.Keybindings:/org/gnome/terminal/legacy/keybindings/ reset-and-clear '<Primary>K'

# Remove multiple workspaces
gsettings set org.cinnamon.desktop.wm.preferences num-workspaces 1

copy() {
    # Linux: xclip (will need install)
    # Mac:   pbcopy
    echo -n "$1" | pbcopy
}
