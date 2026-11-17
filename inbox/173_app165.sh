# App 1.65: Karten-Download ohne automatische Pausen (nur von Hand stoppen)
adb install -r apk/CoreTracker.apk 2>&1 | tail -1
adb shell am start -n at.magixfly.coretracker/.MainActivity >/dev/null 2>&1
sleep 50
for i in 1 2 3 4; do curl -s -m 3 http://127.0.0.1:8080/api/state | python3 -c "import sys,json;b=json.load(sys.stdin).get('box') or {};print(b.get('txt'), b.get('ver'))"; sleep 5; done
