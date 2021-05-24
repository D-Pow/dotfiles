#!/usr/bin/env bash

# Disables certain services that are automatically started at boot.
# In particular, disables services that either:
#   1. Open ports.
#   2. Consume lots of resources.


# Apache server
# Original command (superseded): sudo update-rc.d -f apache2 remove
sudo systemctl disable apache2.service


# Automatic installation of all printers on network
# cups-browsed (service name for cups-browse)
#   This is responsible for installing printer drivers automatically
#   Ref: https://askubuntu.com/questions/345083/how-do-i-disable-automatic-remote-printer-installation
# If that didn't work, try the instructions below.
#   Note, however, that changing the browsing protocols could prevent being able to find/use printers completely, even manually.
#   Open `/etc/cups/cupsd.conf` and/or `/etc/cups/cups-browsed.conf` and change the following key-val pairs (or uncomment them):
#       Browsing Off
#       BrowseLocalProtocols none
#       BrowseProtocols none
sudo systemctl disable cups-browsed


# Docker
sudo systemctl disable docker.service
sudo systemctl disable containerd.service
