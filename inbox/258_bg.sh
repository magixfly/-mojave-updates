top -b -n 3 -d 3 -o %CPU | awk '/^top -/{n++} n==3' | sed -n 3,14p
P=$(pgrep -f "python3.*server.py" | head -1); echo "server pid $P"; top -H -b -n1 -p $P | sed -n 8,16p
cat /proc/net/dev | grep wlan0; sleep 5; cat /proc/net/dev | grep wlan0
iwconfig wlan0 2>/dev/null | grep -i "bit rate\|quality"
dmesg | tail -5
vcgencmd measure_temp; vcgencmd get_throttled
