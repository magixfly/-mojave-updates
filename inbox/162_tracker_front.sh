#screenshot
adb shell am start -n at.magixfly.coretracker/.MainActivity 2>&1 | tail -1
sleep 45
echo "box in state:"; curl -s -m 3 http://127.0.0.1:8080/api/state | python3 -c "import sys,json;print(json.load(sys.stdin).get('box'))" | cut -c1-220
curl -s -m 3 "http://127.0.0.1:8080/api/devices?new=1" >/dev/null; sleep 75
curl -s -m 5 http://127.0.0.1:8080/api/devices | python3 -c "import sys,json;d=json.load(sys.stdin);print('busy',d['busy']);print('box',json.dumps(d['d'].get('box')))" | cut -c1-220
adb shell cat /data/data/at.magixfly.coretracker/shared_prefs/ct.xml | grep '"host"'
