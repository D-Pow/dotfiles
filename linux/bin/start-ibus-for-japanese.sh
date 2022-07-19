#!/usr/bin/env bash

# Japanese through iBus
if [[ -n "$(compgen -c ibus-daemon)" ]]; then
    ibus-daemon &
fi
