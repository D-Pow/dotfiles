Hey everyone, I had a bunch of trouble installing pip on my Mac, so I figured I'd tell you how I did it to save some heartache. (I will also point out that I had to install Python 3 separately from the self service, which I can also help you with, just ask). Anyway, for pip:

1. Make sure you added the proxy information (mentioned above) to your profile. You could even put it in another file (like `.etrade-proxy` or something) and then `source .etrade-proxy` in your `.profile` so you don't expose your password everytime you open .profile. After the proxy is set up, you should be able to use terminal commands.
2. Run `curl https://bootstrap.pypa.io/get-pip.py -o get-pip.py`
3. Run `python get-pip.py` or `python3 get-pip.py`
3. Add the installed pip directories to your path. The directories were located in `/Users/<username>/Library/Python/<version>/bin` for me
4. Change the default python and pip by using aliases in your .profile file