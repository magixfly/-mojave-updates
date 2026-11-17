#nobox
# Geräteliste des Trackers prüfen
curl -s -m 3 "http://127.0.0.1:8080/api/devices?new=1" >/dev/null; sleep 15
curl -s -m 5 http://127.0.0.1:8080/api/devices | python3 -c "import sys,json;d=json.load(sys.stdin);print('busy',d['busy']);[print(x) for x in d['d']]" 2>&1 | cut -c1-200
echo "--- box in state:"; curl -s -m 3 http://127.0.0.1:8080/api/state | python3 -c "import sys,json;d=json.load(sys.stdin);print(d.get('box'))" 2>&1 | cut -c1-200
echo "--- app läuft?"; adb shell pidof at.magixfly.coretracker; adb shell dumpsys package at.magixfly.coretracker | grep -m1 versionName
journalctl -u coretracker --since '-30min' --no-pager 2>/dev/null | grep -iE 'devices|error|Traceback' | tail -5 | cut -c1-200
