premarketpath="/Users/dpowell1/repositories/etdash/html/premarket"
cd $premarketpath && rm -rf ./_* index.html
tar zfxv premarket.tar.gz && mv premarket_qdevon/* . && rm -r premarket_qdevon
rm -f premarket.tar.gz sendgit.sh update_etdash.sh test_update_etdash.sh
