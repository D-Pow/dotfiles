ip="$1"
#path="$2"  #replace $2 with specific path if you want to always go to the same place
path="/Users/dpowell1/repositories/etdash/html/premarket"
dest="$ip:$path"
#scp -recursive source dest
#recurse on maxdepth/level 1 in order to retain dir hierarchy
#find . -maxdepth 1 -not -name sendgit.sh -not -name . -exec scp -r {} "$dest" \;
tar --exclude="sendgit.sh" --exclude="update_etdash.sh" --exclude=".DS_Store" -zcvf "premarket.tar.gz" "../premarket_qdevon/"
scp "premarket.tar.gz" "$dest"
rm premarket.tar.gz
ssh "$ip" "$path/extract_tar.sh"
