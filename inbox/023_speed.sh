# Geschwindigkeit Box <-> Pi messen
echo "Ping Pi->Box:"; ping -c 10 -i 0.3 172.20.10.14 | tail -2
echo "Ping Box->Pi:"; adb shell ping -c 10 -i 0.3 172.20.10.2 | tail -2
iwconfig wlan0 2>/dev/null | grep -E 'Bit Rate|Frequency' ; iw dev wlan0 link 2>/dev/null | grep -E 'freq|tx bitrate|signal'
adb shell 'which curl wget toybox' 
dd if=/dev/urandom of=/tmp/t.bin bs=1M count=3 2>/dev/null
echo "Upload 3 MB Pi->Box:"; S=$(date +%s.%N); adb push /tmp/t.bin /data/local/tmp/t.bin | tail -1; E=$(date +%s.%N); echo "$(echo "$E - $S" | bc) s"
adb shell rm /data/local/tmp/t.bin
