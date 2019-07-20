#(...) array syntax
ipaddresses=($(ifconfig | egrep -o "([0-9]{1,3}\.){3}[0-9]{1,3}"))
localip="${ipaddresses[1]}"

echo "All IPs:"
for i in "${ipaddresses[@]}"
do
    echo "$i"
done
echo -e "\nYour guessed IP:"
echo $localip
