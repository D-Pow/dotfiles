1. `export http_proxy=http://user:pass@iadwg-lb.corp.etradegrp.com:9090/` and point the rest of the proxy family to it, e.g.
    ```
    export http_proxy=http://user:pass@iadwg-lb.corp.etradegrp.com:9090/
    export HTTP_PROXY=$http_proxy
    export https_proxy=$http_proxy
    export HTTPS_PROXY=$http_proxy
    ```
2. install homebrew
3. `brew install cntlm`
4. `cntlm -H` to get hashes
5. Open /usr/local/etc/cntlm.conf for the changes below:
    1. Username    <username>
    2. Domain        corp.etradegrp.com
    3. (comment out Password)
    4. Paste results of cntlm -H in the PassNT and PassLM sections (***including AUTH     NTLM***)
    5. Comment out PassNTLMv2
    6. Proxy        iadwg-lb.corp.etradegrp.com:9090
6. Change .profile `export http_proxy=http://localhost:3128`
7. Run `cntlm` before doing things online. I recommend calling it in your .profile
