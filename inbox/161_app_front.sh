#screenshot
# Core-Tracker-App in den Vordergrund holen, dann prüfen ob sie sich beim Tracker meldet
adb shell monkey -p at.magixfly.coretracker -c android.intent.category.LAUNCHER 1 >/dev/null 2>&1
sleep 40
echo "box in state:"; curl -s -m 3 http://127.0.0.1:8080/api/state | python3 -c "import sys,json;print(json.load(sys.stdin).get('box'))" | cut -c1-200
curl -s -m 3 "http://127.0.0.1:8080/api/devices?new=1" >/dev/null; sleep 70
curl -s -m 5 http://127.0.0.1:8080/api/devices | python3 -c "import sys,json;d=json.load(sys.stdin);print('busy',d['busy']);print('box',json.dumps(d['d'].get('box')))" | cut -c1-200
adb shell cat /data/data/at.magixfly.coretracker/shared_prefs/ct.xml | grep '"host"'
