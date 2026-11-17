#nobox
H=192.168.178.175
curl -s -m 4 -i "http://$H/" | head -c 1500; echo
for p in index.html wifi wifi.html network network.html settings settings.html api/wifi api/status status cgi-bin/wifi; do printf "%-16s " $p; curl -s -m 4 -o /tmp/p -w "%{http_code} %{size_download}\n" "http://$H/$p"; done
