#!/usr/bin/env bash

# Japanese through iBus
# Only run the command if it exists and the daemon isn't running already
if [[ -n "$(compgen -c ibus-daemon)" ]] && [[ -z "$(listprocesses ibus-daemon)" ]]; then
    ibus-daemon &
fi
