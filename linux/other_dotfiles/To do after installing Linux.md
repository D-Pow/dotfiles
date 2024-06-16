# To do after installing Linux:

Note: to change the environment PATH variable, go to `/etc/environment` and separate entries using a colon.


* Follow the tutorial [here](https://www.howtogeek.com/howto/35807/how-to-harmonize-your-dual-boot-setup-for-windows-and-ubuntu/) to setup shared NTFS Windows-Linux storage partition.
    - Generally, the steps are:
        1. Backup fstab:
            ```
            sudo cp /etc/fstab /etc/fstab.backup
            ```
        2. Get UUID of storage partition:
            ```
            sudo blkid
            ```
        3. Edit fstab to mount storage NTFS partition automatically. Paste at bottom of fstab:
            ```
            # storage mount
            UUID=[UUID_of_storage] /media/storage/    ntfs-3g        auto,dmask=022,fmask=011,uid=1000,gid=1000,rw 0 2
            ```
        where `UUID` is the UUID of the storage partition from step (2), `/media/storage` is the new mount point, `ntfs-3g` is the driver used to read NTFS, `dmask` is directory permissions (need to be rwx for owner), `fmask` is file permissions (need to not be executable so that I can read txt files easily), `uid/gid` set owner to user (note: this may have to change depending on installation; run `id -u` to get userid and `id -g` to get groupid).
        4. Edit `~/.config/user-dirs.dirs` to point to storage partition's Documents, Picturs, Music, and Video folders.


* Install correct drivers (super important!!). Will need `quiet splash nomodeset` along with the drivers below (there might be some that are more up-to-date or that are/n't needed anymore from newer upgrades).
    - Best way: Go to `Settings --> Administration --> Driver Manager` and click the latest proprietary Nvidia drivers.
    - Drivers may include:
    ```
    nvidia-prime
    nvidia-prime-applet
    nvidia-settings
    nvidia-123
    nvidia-compute-utils-123
    nvidia-dkms-123
    nvidia-driver-123
    nvidia-kernel-common-123
    nvidia-kernel-source-123
    nvidia-utils-123
    nvidia-opencl-icd-123
    ```
    - See more info in my reddit post here (https://www.reddit.com/r/linuxquestions/comments/eqdugr/any_way_to_diable_my_gpu_before_boot/fet00g0?utm_source=share&utm_medium=web2x).
    - If you're still running into issues (e.g. booting shows "No hardware acceleration"), then load the Nvidia kernel modules earlier in the boot process:
    ```
    # /etc/modules - Add these lines
    nvidia
    nvidia-drm
    nvidia-modeset
    ```
    - For multi-monitor setups, everything should run smoothly automatically. If you experience many issues, you could make two separate X screen servers rather than allowing one server to handle multiple screens, though this isn't recommended b/c it breaks some features (e.g. dragging windows between screens, hardware acceleration between both screens, etc.). To do so, see: https://download.nvidia.com/XFree86/Linux-x86_64/384.98/README/configmultxscreens.html


* Install updates.


* Fix Linux/Windows time configuration:
* Changing Linux (UTC) to match Windows (RTC)
    - Unfortunate but easier and allows for both to update automatically with daylight savings.
    - `gksudo gedit /etc/default/rcS` --> add/change `UTC=yes`
    - `timedatectl set-local-rtc 1` Changes from UTC to local (Windows uses local)
    - If you want to switch back to UTC on Linux, replace `1` with `0`
* Changing Windows to match Linux
    - https://superuser.com/questions/884278/windows-vs-linux-local-time/884311#884311
    - Regedit --> `HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\TimeZoneInformation`
    - Add/update `RealTimeIsUniversal=(dword)00000001`


* Add the following to Settings --> Startup Applications
    - Mount Google Drive
        + Title: `Mount Google Drive`
        + Command: `gio mount google-drive://djp460@nyu.edu/`
        + Delay: `10s`
    - Start Discord on boot
        + Title: `Discord - start on boot`
        + Command: `discord --start-minimized`
        + Delay: `10s`
    - Start iBus (Japanese)
        + Title: `Start iBus (Japanese)`
        + Command: `/path/to/repositories/linux/bin/start-ibus-for-japanese.sh`
        + Delay: `10s`
    - Numlock:
        + Title: `Turn on numlock`
        + Command: `turn-on-numlock`
        + Delay: `10s`
    - Changing desktop background image:
        + Title: `Change background`
        + Command: `change-desktop-image`
        + Delay: `15s`
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
    - Ensure `dotfiles/linux/linux.profile` has `JAVA_HOME` pointing to the correct dir.
    - Run `source ~/.profile`
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
    - If the symlinks in `linux/bin/pythonX` don't work, then add this to .profile
    ```
    alias python3=python3.X
    ```


* Set numlock to always be on:
    - Keyboard (settings) -> Layouts -> Options -> Miscellaneous Compatibility Options
    - Activate:
        + `Default Numeric Keys`
        + `Numeric keypad always enter digits`


* For Japanese input in Linux:
    - Install Japanese and its language packs from `Languages` settings menu.
    - Install `iBus` and `ibus-mozc` from Software Manager (GUI).
    - Install `fcitx-mozc` from apt.
    - Ensure the Japanese layout is *not* in `Keyboard` -> `Layouts` settings menu.
        + Likewise, ensure the `Options` -> `Switching to another layout` has no key combos checked.
    - In `iBus Preferences`:
        + "Next input method" --> `Ctrl+Super+Space`.
            * `Super+Space` works, but you have to hold it down to avoid it registering as a regular space, so this is easier.
        + "Show property panel" --> `Do not show`.
            * This hides an annoying GUI popup when using Mozc.
    - In `Mozc settings` (from either iBus.Japanese or the OS panel when Mozc/Japanese is selected):
        + Space input style --> Halfwidth
        + General --> Keymap style --> Import --> `./mozc-keymap-style.txt`
        + Advanced --> Shift key mode switch --> Katakana
    - ***IFF*** you encounter issues:
        + iBus isn't starting on boot: Add this to `$HOME/.bashrc`
        ```bash
        if [[ -n "$(compgen -c ibus-setup)" ]]; then
            export GTK_IM_MODULE=ibus
            export XMODIFIERS=@im=ibus
            export QT_IM_MODULE=ibus

            if ! ps aux | grep -i ibus | grep -iq mozc; then
                ibus-daemon &
            fi
        fi
        ```
        - Something else:
            + Install `Fcitx` from the Software Manager (GUI).


* Copy `home_config_backups/*` to `~`.


* Import personalized settings for the following items via `dconf` in [./dconf_dumps/](./dconf_dumps/ReadMe.md)
    - Do this **after** installing programs and copying the `home_config_backups/*` dirs to the home `~` dir.


* If dconf for keyboard shortcuts didn't work, then add useful keyboard shortcuts manually
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
    - Remap `Toggle Scale` (shows all windows for switching between them in an Alt+Tab-esque manner):
        + General > Toggle Scale > `Super+Tab`
    - Remove `Toggle Expo` (shows all workspaces):
        + General > Toggle Expo > Remove all keybindings
    - Remove workspaces:
        + `gsettings set org.cinnamon.desktop.wm.preferences num-workspaces 1`
        + `linux.profile` already has this in it.


* Allow webpack to auto-recompile code (sometimes not allowed by certain installations):
    - Run:
    ```
    echo fs.inotify.max_user_watches=524288 | sudo tee -a /etc/sysctl.conf && sudo sysctl -p
    ```
    - [Reference](https://github.com/webpack/docs/wiki/troubleshooting#not-enough-watchers)


* For LaTeX (TexLive), run the following commands:
    - `tlmgr init-usertree`
    - `tlmgr update --self --all --reinstall-forcibly-removed`
    - If that fails, you'll have to switch to the old repo (tlmgr not supported in new one):
    ```
    tlmgr option repository ftp://tug.org/historic/systems/texlive/2015/tlnet-final
    ```
        + Use sudo for installing things
    - To uninstall:
        + [Do this first](https://tex.stackexchange.com/questions/95483/how-to-remove-everything-related-to-tex-live-for-fresh-install-on-ubuntu/95502#95502)
            * Also, `sudo apt remove --purge tex-*`
            * Gist:
                ```bash
                sudo rm -rf /usr/local/tex* ~/.texmf* /usr/local/share/texmf/ rm -rf ~/texmf*
                find -L /usr/local/bin/ -lname /usr/local/texlive/*/bin/* | sudo xargs rm -r
                ```


* For Heroku CLI:
    - Install instructions: https://devcenter.heroku.com/articles/heroku-cli
    - If apt can't validate the public key for heroku, add via: `curl https://cli-assets.heroku.com/apt/release.key | sudo apt-key add -`


* If dual-booting, convert the disk from MBR (Master Boot Record) to GPT (GUID):
    - Install Linux first so Grub is accessible.
    - Change BIOS to boot using UEFI instead of Legacy.
    - If the Linux install didn't automatically convert the disk to GPT:
        + Use MBR2GPT in Windows to convert it: https://docs.microsoft.com/en-us/windows/deployment/mbr-to-gpt
        + MBR2GPT prefers to be run in the Windows Preinstallation Environment rather than in a booted OS. It's possible to run in the OS, but you could run into issues, e.g. the system recovery being messed up.


* Grub Customizer details
    - Generally, this should be redone by hand, but in case the entries are missing/confusing, the settings are pasted here.
    - **Note**: `savedefault` is required in entries to allow "Boot previously booted entry" to work. It's usually automatically added to `/boot/grub/grub.cfg` in Linux entries, but not Windows. In either case, add it manually if it doesn't exist.
    - `General settings`
        + Default entry
            * Previously booted entry
        + Visibility (check the following)
            * Show menu
            * Look for other configurations
            * Boot default entry after `7 seconds`
        + Kernel parameters
            * `quiet splash`
            * Generate recovery entries
    - `Appearance settings`
        + Font: `DejaVu Sans Book - 16 pt`
    - `List configuration`:
    - Entry:
        + Name: `Windows 10`
        + Type: `Other`
        + Boot sequence:
            ```
            savedefault
            search --fs-uuid --no-floppy --set=root 2AC0-4083
            chainloader (${root})/EFI/Boot/bkpbootx64.efi
            ```
    - Entry:
        + Name: `Linux <version>`
        + Type: `Other`
        + Boot sequence:
            ```
            recordfail
            savedefault
            load_video
            gfxmode $linux_gfx_mode
            insmod gzio
            if [ x$grub_platform = xxen ]; then insmod xzio; insmod lzopio; fi
            insmod part_gpt
            insmod ext2
            set root='hd1,gpt7'
            if [ x$feature_platform_search_hint = xy ]; then
              search --no-floppy --fs-uuid --set=root --hint-bios=hd1,gpt7 --hint-efi=hd1,gpt7 --hint-baremetal=ahci1,gpt7  fb226918-a90f-4d75-a3a8-f833ceba7eb1
            else
              search --no-floppy --fs-uuid --set=root fb226918-a90f-4d75-a3a8-f833ceba7eb1
            fi
                    linux   /boot/vmlinuz-4.15.0-142-generic root=UUID=fb226918-a90f-4d75-a3a8-f833ceba7eb1 ro  quiet splash $vt_handoff
            initrd  /boot/initrd.img-4.15.0-142-generic
            ```
    - Entry:
        + Name: `Windows 10 Troubleshooting`
        + Type: `Other`
        + Boot sequence:
            ```
            search --fs-uuid --no-floppy --set=root C25F-9A06
            chainloader (${root})/EFI/Boot/bkpbootx64.efi
            ```
    - Entry:
        + Name: `System setup`
        + Type: `Other`
        + Boot sequence:
            ```
            fwsetup
            ```


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


* If running into `apt` PPA key issues after upgrading OS version with `Key is stored in legacy trusted.gpg keyring (/etc/apt/trusted.gpg), see the DEPRECATION section in apt-key(8) for details.`, follow the instructions [here](https://softhints.com/linux-mint-w-key-is-stored-in-legacy-trusted-gpg-keyring-etc-apt-trusted-gpg-see-the-deprecation-section-in-apt-key-8-for-details). The gist:
    - Get the PPA repo's name from the error message, `W: http://ppa.launchpad.net/<name>/some/path: Key is stored...`.
    - Run `sudo apt-key list` and look in the top of the output for the top-level `/etc/apt/trusted.gpg` that lacks a subpath after it for the PPA we want.
    - Get the last 8 characters from the `pub rsa` output hash string (will have a space in the middle, e.g. `A1B2 C3D4`).
    - Run `sudo apt-key export <8-chars-without-space> | sudo gpg --dearmour -o /etc/apt/trusted.gpg.d/<repo-name>.gpg` to add the key from top-level `/etc/apt/trusted.gpg` to its own `/etc/apt/trusted.gpg.d/<repo-name>.gpg`.
    - Run `sudo apt-key --keyring /etc/apt/trusted.gpg del <8-chars-without-space>` to remove the key from the top-level `/etc/apt/trusted.gpg`.


* To allow Bluetooth pairing of a device on both Windows/Linux:
    - Refs:
        + https://unix.stackexchange.com/questions/255509/bluetooth-pairing-on-dual-boot-of-windows-linux-mint-ubuntu-stop-having-to-p
        + https://gist.github.com/madkoding/f3cfd3742546d5c99131fd19ca267fd4
    - Run:
        ```bash
        cd /mnt/c/Windows/System32/config
        chntpw -e SYSTEM
        cd \ControlSet001\Services\BTHPORT\Parameters\Keys
        cd [ID]
        hex [ID]
        ```

* To move Linux partition to other disk:
    - Use [Clonezilla](https://clonezilla.org).
        + Probably don't want to reinstall Grub, but this needs to be fact-checked.
    - If UUID isn't changed, resulting in >= 2 drives/partitions with the same UUID:
        + Change UUID of partition: `tune2fs -U $(uuidgen) /dev/sd{X}{Y}` (where X is disk and Y is partition).
        + Update Grub with new UUID.
            * Might need to change Grub mount partition via `File` --> `Change Environment` --> `Partition`.
        + See:
            * [SO answer: New UUID for partition with `tune2fs`](https://unix.stackexchange.com/questions/12858/how-to-change-filesystem-uuid-2-same-uuid/12859#12859)
            * [SO answer: Alternative method with `sfdisk`](https://unix.stackexchange.com/questions/752848/how-can-you-give-a-disk-and-a-new-uuid)
    - Helpful commands:
        + List drive info: `sudo sfdisk --dump /dev/sda`
        + List all drives, refreshing RAM/cache:
            - `sudo df --all`
            - `sudo mount -l | grep -Pi '/dev/sd'`
            - `sudo blkid -p /dev/sda`
