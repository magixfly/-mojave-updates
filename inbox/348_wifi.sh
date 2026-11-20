#nobox
nmcli -t -f NAME,TYPE,AUTOCONNECT,AUTOCONNECT-PRIORITY connection show | grep -i wireless
nmcli -t -f ACTIVE,SSID,CHAN,SIGNAL dev wifi | head -12
