#screenshot
# App 1.64: Tracker per IP statt corepi.local (Box löst .local nicht auf) -> Kia-Ansicht am Pi
adb install -r apk/CoreTracker.apk 2>&1 | tail -1
adb shell am start -n at.magixfly.coretracker/.MainActivity >/dev/null 2>&1
sleep 50
for i in 1 2 3; do curl -s -m 3 http://127.0.0.1:8080/api/state | python3 -c "import sys,json;b=json.load(sys.stdin).get('box') or {};print('box:', b.get('txt'), b.get('ver'), b.get('ip'))"; sleep 4; done
adb shell cat /data/data/at.magixfly.coretracker/shared_prefs/ct.xml | grep '"host"'
