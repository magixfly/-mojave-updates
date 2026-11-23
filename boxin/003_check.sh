dumpsys package at.magixfly.coretracker | grep -m1 versionName
dumpsys wifi | grep -m3 -E "mWifiInfo|SSID:.*Link speed" | cut -c1-300
ping -c 10 -i 0.2 192.168.178.175 | tail -2
top -b -n 1 -m 8 | head -14
cat /sys/class/thermal/thermal_zone0/temp
curl -s -m 3 http://192.168.178.175/ | grep -o -i -E "transcod[a-z]*|resolution[^<]{0,40}" | head -5
