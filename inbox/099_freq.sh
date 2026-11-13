#nobox
# Welches Band hat der Hotspot XVII gerade? (Pi-Sicht)
nmcli -f IN-USE,SSID,BSSID,CHAN,FREQ,SIGNAL,RATE dev wifi list 2>&1 | grep -E '^\*'
ip route | awk '/^default/{print "Gateway",$3}'; hostname -I
ping -c 10 -i 0.3 -q $(ip route | awk '/^default/{print $3; exit}') | tail -1
