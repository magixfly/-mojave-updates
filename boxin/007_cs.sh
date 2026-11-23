#screenshot
dumpsys package at.magixfly.coretracker | grep -m1 versionName
ping -c 20 -i 0.2 -W 1 192.168.178.175 2>&1 | tail -2
curl -s -m 3 -o /dev/null -w "cs http %{http_code} %{time_total}s\n" http://192.168.178.175/
top -b -n 1 -m 6 | sed -n 4,11p
