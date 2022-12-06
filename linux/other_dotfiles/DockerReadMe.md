Docker's [installation instructions](https://docs.docker.com/engine/install/ubuntu/#install-using-the-repository) are incomplete and have outdated/inaccurate information.

The correct steps are:

* Uninstall previous versions:
    - `sudo apt-get remove docker docker-engine docker.io containerd runc`
* Add Docker's GPG key:
    - `curl -fsSL https://download.docker.com/linux/debian/gpg | sudo apt-key add -`
* Add the apt repository PPA
    - Note: The command below is only needed over the command they provided on their website if using an Ubuntu offshoot, like Linux Mint.
        + Similarly, `xenial` should be replaced with the respective version that the Linux Mint version branched from.
    - `sudo add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu xenial stable"`
    - If necessary, downgrade Docker's OS version to the previous version.
        + See: [StackOverflow answer to Linux Mint's issue with Docker not supporting Una (i.e. `lsb_release -cs` issue)](https://unix.stackexchange.com/questions/707420/docker-repo-isnt-adding-correctly-on-linux-mint-20-3-una/724222#724222).
* Prevent Docker from running on startup:
    - `sudo systemctl disable docker.service`
    - `sudo systemctl disable containerd.service`
* Make Docker runnable by users rather than only root:
    - `sudo groupadd docker`
    - `sudo usermod -aG docker $(whoami)`
    - Restart

View more [Linux post-install instructions](https://docs.docker.com/engine/install/linux-postinstall/).
