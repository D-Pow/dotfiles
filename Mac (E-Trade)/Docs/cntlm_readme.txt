1) `brew install cntlm`
2) `cntlm -H` to get hashes
3) Open /usr/local/etc/cntlm.conf for the changes below:
    1) Username    <username>
    2) Domain        corp.etradegrp.com
    3) (comment out Password)
    4) Paste results of cntlm -H in the PassNT and PassLM sections (***including AUTH     NTLM***)
    5) Comment out PassNTLMv2
    6) Proxy        iadwg-lb.corp.etradegrp.com:9090
5) Change .profile `export http_proxy=http://localhost:3128` along with rest of the `_proxy` family
6) Run `cntlm` before doing online stoofs