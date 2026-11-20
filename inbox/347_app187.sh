#nobox
# App 1.87: Hotspot nur, wenn kein WLAN verbunden. Wartet bis 10 min auf die Box.
for i in $(seq 1 60); do adb connect 192.168.178.235:5555 >/dev/null 2>&1; adb -s 192.168.178.235:5555 get-state 2>/dev/null | grep -q device && break; sleep 10; done
adb -s 192.168.178.235:5555 install -r apk/CoreTracker.apk 2>&1 | tail -1
adb -s 192.168.178.235:5555 shell am start -n at.magixfly.coretracker/.MainActivity >/dev/null 2>&1
