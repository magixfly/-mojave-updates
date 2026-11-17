#nobox
# CosmoStreamer-Status im Heimnetz
H=192.168.178.175
ping -c3 -i 0.3 -W2 $H | tail -1
curl -s -m 5 http://$H/ | sed 's/<[^>]*>/ /g' | tr -s ' \n' ' ' | grep -oiE '(firmware|version|camera|temperature|temp|cpu|connected|bitrate|kbits)[^.]{0,60}' | head -15
for p in /api/status /status /api/info /info.json; do printf "%s -> " $p; curl -s -m 3 -o /tmp/c.out -w "%{http_code}" http://$H$p; echo " $(head -c 200 /tmp/c.out | tr '\n' ' ')"; done
