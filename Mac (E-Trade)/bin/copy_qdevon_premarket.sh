qdevon="/Users/dpowell1/dashboard/html/premarket_qdevon"
premarket="/Users/dpowell1/repositories/etdash/html/premarket"
cd $premarket && rm -rf "./*"
cd $qdevon && cp -r ./* $premarket
echo "done"