# To do after installing Linux:

Note: to change the environment PATH variable, go to `/etc/environment` and separate entries using a colon.


* Follow the tutorial [here](https://www.howtogeek.com/howto/35807/how-to-harmonize-your-dual-boot-setup-for-windows-and-ubuntu/) to setup shared NTFS Windows-Linux storage partition.
    - Generally, the steps are:
        1. Backup fstab:<br/>
            ```
            sudo cp /etc/fstab /etc/fstab.backup
            ```
        2. Get UUID of storage partition:<br/>
            ```
            sudo blkid
            ```
        3. Edit fstab to mount storage NTFS partition automatically. Paste at bottom of fstab:
            ```
            # storage mount
            UUID=[UUID_of_storage] /media/storage/    ntfs-3g        auto,dmask=022,fmask=011,uid=1000,gid=1000,rw 0 0
            ```
        where `UUID` is the UUID of the storage partition from step (2), `/media/storage` is the new mount point, `ntfs-3g` is the driver used to read NTFS, `dmask` is directory permissions (need to be rwx for owner), `fmask` is file permissions (need to not be executable so that I can read txt files easily), `uid/gid` set owner to user (note: this may have to change depending on installation; run `id -u` to get userid and `id -g` to get groupid).
        4. Edit `~/.config/user-dirs.dirs` to point to storage partition's Documents, Picturs, Music, and Video folders.


* Install correct drivers (super important!!). Will need `quiet splash nomodeset` along with the drivers in "Nvidia installations.txt" or similar (there might be some that are more up-to-date). See my reddit post here (https://www.reddit.com/r/linuxquestions/comments/eqdugr/any_way_to_diable_my_gpu_before_boot/fet00g0?utm_source=share&utm_medium=web2x).


* Install updates.


* Fix Linux/Windows time configuration
    - `gksudo gedit /etc/default/rcS` --> add/change `UTC=yes`
    - `timedatectl set-local-rtc 1` Changes from UTC to local (Windows uses local)
    - If you want to switch back to UTC on Linux, replace `1` with `0`


* Add the following to Settings --> Startup Applications
    - Numlock:
        + Title: `Turn on numlock`
        + Command: `turn-on-numlock`
        + Delay: `10s`
    - Changing desktop background image:
        + Title: `Change background`
        + Command: `change-desktop-image`
        + Delay: `0s`
    - Keyboard key re-maps:
        + Title: `Map R-Ctrl to Menu`
        + Command: `custom-key-mapping -a`
        + Comment: `Only remap key on internal keyboard`
        + Delay: `10s`
    - (Optional) Disable bluetooth on boot (only if not using bluetooth devices):
        + Title: `Turn off bluetooth`
        + Command: `bluetoothoff`
        + Delay: `0s`
* Similarly, turn off unwanted startup services via `./disable-startup-services.sh`.
    - Only run once, not in .profile/Startup Applications


* Turn off Windows quick-boot
    - If Linux won't boot randomly and only goes into emergency mode, boot into Windows and run
    ```
    shutdown /s /t 5
        /s = shutdown
        /r = restart
        /t [number] = timeout
    ```
    - Note: this is only if you didn't change any settings to break Linux (e.g. changing drivers). Once, Windows wouldn't let go of my shared Storage partition, even after shutting down. Running shutdown in command prompt helped for some reason.


* To add GitHub oauth personal access token via credential manager:
    - `sudo apt install libsecret-1-0 libsecret-1-dev`
    - `cd /usr/share/doc/git/contrib/credential/libsecret/`
    - `sudo make`
    - `git config --global credential.helper /usr/share/doc/git/contrib/credential/libsecret/git-credential-libsecret`
    - `cd some-git-dir`
    - `git pull`
    - paste oauth token in password section


* To install Java, you'll want to remove the underscore for the directory name.
    - First, install Java to /usr/
    - Rename the directory to just "java" and remove jdk_1.*.* name in folder
    - Ensure `dotfiles/Linux/Linux.profile` has `JAVA_HOME` pointing to the correct dir.
    - Run `source ~/.profile`
    <br/>
    - If the above didn't work, then:
        + Edit `/etc/environment`:
            * Add `JAVA_HOME=/usr/java/bin` under the PATH line
            * Add `:$JAVA_HOME/bin` to end of PATH line to add the bin folder to path
        + In terminal, run `source /etc/environment` to update system-wide environment variables.


* To install latest Python (since apt doesn't have Python > 3.5)
    - Run:
    ```
    sudo apt update
    sudo apt install software-properties-common
    sudo add-apt-repository ppa:deadsnakes/ppa
    sudo apt install python3.X
    ```
    - Add to .profile
    ```
    alias python3=python3.X
    ```


* Set numlock to always be on:
    - Keyboard (settings) -> Layouts -> Options -> Miscellaneous Compatibility Options
    - Activate:
        + `Default Numeric Keys`
        + `Numeric keypad always enter digits`


* Add useful keyboard shortcuts:
    - System > Lock screen > Super+L
    - Custom:
        + Open sublime - Ctrl+Alt+S
        ```
        subl
        ```
        + Home button to play/pause Spotify (for Kinesis keyboard) - HomePage
        ```
        dbus-send --print-reply --dest=org.mpris.MediaPlayer2.spotify /org/mpris/MediaPlayer2 org.mpris.MediaPlayer2.Player.PlayPause
        ```
        + Open Discord - Ctrl+Alt+D
        ```
        /usr/bin/discord
        ```
    - Remap `Toggle Scale` (spreads all windows to tabl through):
        + General > Toggle Scale > `Super+Tab`
    - Remove `Toggle Expo` (shows all workspaces):
        + General > Toggle Expo > Remove all keybindings
    - Remove workspaces:
        + `gsettings set org.cinnamon.desktop.wm.preferences num-workspaces 1`
        + `Linux.profile` already has this in it.


* Import terminal profile settings:
    - Import:
    ```
    dconf load /org/gnome/terminal/ < gnome_terminal_settings.txt
    ```
    - Export:
    ```
    dconf dump /org/gnome/terminal/ > gnome_terminal_settings.txt
    ```


* Allow webpack to auto-recompile code (sometimes not allowed by certain installations):
    - Run:
    ```
    echo fs.inotify.max_user_watches=524288 | sudo tee -a /etc/sysctl.conf && sudo sysctl -p
    ```
    - [Reference](https://github.com/webpack/docs/wiki/troubleshooting#not-enough-watchers)


* In Linux, after installing Mozc and IBus (for Japanese input):
    - Mozc settings
        + Keymap style --> Import --> `./mozc-keymap-style.txt`
        + Space input style --> Halfwidth
        + Advanced --> Shift key mode switch --> Katakana
    - IBus
        + Next input method --> Ctrl+Super+Space (Super+Space doesn't work for some reason)


* For LaTeX (TexLive), run the following commands:
    - `tlmgr init-usertree`
    - `sudo tlmgr update --all`
    - If that fails, you'll have to switch to the old repo (tlmgr not supported in new one):
    ```
    tlmgr option repository ftp://tug.org/historic/systems/texlive/2015/tlnet-final
    ```
        + Use sudo for installing things


* For Heroku CLI:
    - Install instructions: https://devcenter.heroku.com/articles/heroku-cli
    - If apt can't validate the public key for heroku, add via: `curl https://cli-assets.heroku.com/apt/release.key | sudo apt-key add -`


* If dual-booting, convert the disk from MBR (Master Boot Record) to GPT (GUID):
    - Install Linux first so Grub is accessible.
    - Change BIOS to boot using UEFI instead of Legacy.
    - If the Linux install didn't automatically convert the disk to GPT:
        + Use MBR2GPT in Windows to convert it: https://docs.microsoft.com/en-us/windows/deployment/mbr-to-gpt
        + MBR2GPT prefers to be run in the Windows Preinstallation Environment rather than in a booted OS. It's possible to run in the OS, but you could run into issues, e.g. the system recovery being messed up.


* If running into issues with GRUB after modifying boot partitions (e.g. deleting/moving partitions you can boot from):
    - Boot into live Linux USB.
    - Mount the "Linux filesystem" drive in the USB instance
        + `sudo fdisk -l`
        + `sudo blkid`
        + Get the /dev/sdXX of "Linux Filesystem"
        + `sudo mount /dev/sdXX /mnt` to mount that partition into /mnt/ directory
    - Run "Boot repair" (in start menu) or `boot-repair` (in terminal).
        + Advanced options
        + Uncheck "Secure Boot" (secure boot was disabled above)
        + Uncheck "Repair Windows boot loader" (Windows data should be totally fine, only GRUB is messed up)
    - Reboot into Linux on hard drive and re-run GrubCustomizer to customize as desired.
