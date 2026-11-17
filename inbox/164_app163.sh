#screenshot
# App 1.63 installieren (Box-WLAN statt fälschlich "Hotspot"), Karte öffnen
adb install -r apk/CoreTracker.apk 2>&1 | tail -1
adb shell dumpsys package at.magixfly.coretracker | grep -m1 versionName
adb shell am start -n at.magixfly.coretracker/.MainActivity >/dev/null 2>&1
sleep 45
curl -s -m 3 http://127.0.0.1:8080/api/state | python3 -c "import sys,json;b=json.load(sys.stdin).get('box') or {};print('wifi:',b.get('wifi'),'ver:',b.get('ver'))"
