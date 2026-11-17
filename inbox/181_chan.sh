#nobox
nmcli -f SSID,CHAN,FREQ,SIGNAL,SECURITY dev wifi list 2>&1 | grep -E "SSID|Media|Optimus" | head
