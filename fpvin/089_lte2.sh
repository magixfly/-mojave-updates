#timeout 120
echo "== usb"; lsusb | grep -v "Linux Foundation"
echo "== net"; ip -br addr | grep -v "^lo"
echo "== routes"; ip route
echo "== driver"; for i in /sys/class/net/*; do n=$(basename $i); [ -e $i/device/driver ] && echo "$n $(basename $(readlink $i/device/driver)) $(cat $i/address)"; done
echo "== nm"; nmcli -t -f DEVICE,TYPE,STATE,CONNECTION dev 2>/dev/null | grep -v "^lo"
echo "== wifi seen"; nmcli -t -f SSID,SIGNAL dev wifi list 2>/dev/null | head -6; rfkill list 2>/dev/null | grep -A2 -i wlan | tr '\n' ' '; echo
echo "== ping"; ping -c 8 -i 0.3 -q 1.1.1.1 | tail -2
echo "== public"; curl -s -m 8 https://ifconfig.me; echo
echo "== stick page"; GW=$(ip route | awk '/default/{print $3; exit}'); echo "gw $GW"; curl -s -m 6 -o /dev/null -w "http %{http_code} %{size_download} bytes\n" http://$GW/
echo "== upload 4 MB"; head -c 4000000 /dev/urandom > /tmp/up.bin; curl -s -m 40 -o /dev/null -w "up %{speed_upload} B/s in %{time_total} s\n" -F "f=@/tmp/up.bin" https://speed.cloudflare.com/__up; rm -f /tmp/up.bin
echo "== download 5 MB"; curl -s -m 40 -o /dev/null -w "down %{speed_download} B/s\n" "https://speed.cloudflare.com/__down?bytes=5000000"
echo "== tailscale"; tailscale status 2>/dev/null | head -6; tailscale netcheck 2>/dev/null | grep -E "UDP|Nearest|MappingVaries|IPv4|IPv6" 
echo "== power"; vcgencmd get_throttled; vcgencmd measure_temp
echo "[100%] done"
