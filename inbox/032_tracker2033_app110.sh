#screenshot
# App 1.10 installieren; Tracker auf 2.0.33 aktualisieren, sobald GitHub die neue Version liefert (Cache bis ~5 min)
adb push apk/CoreTracker.apk /sdcard/Download/coretracker.apk >/dev/null
S=$(adb shell stat -c %s /sdcard/Download/coretracker.apk | tr -d '\r')
adb shell "cat /sdcard/Download/coretracker.apk | pm install -r -S $S"
for i in $(seq 1 14); do
  curl -s -X POST -H 'Content-Type: application/json' -d '{"check":1}' http://127.0.0.1:8080/api/update >/dev/null; sleep 8
  v=$(curl -s http://127.0.0.1:8080/api/update); case "$v" in *2.0.33*) echo "online: 2.0.33"; break;; esac; sleep 20
done
curl -s -X POST -H 'Content-Type: application/json' -d '{"install":1}' http://127.0.0.1:8080/api/update; echo
for i in $(seq 1 30); do sleep 3; v=$(curl -s http://127.0.0.1:8080/api/update 2>/dev/null); case "$v" in *'"cur": "2.0.33"'*) echo "Tracker 2.0.33 läuft"; break;; esac; done
adb shell monkey -p at.magixfly.coretracker -c android.intent.category.LAUNCHER 1 >/dev/null 2>&1
adb shell am force-stop at.magixfly.coretracker; sleep 1; adb shell monkey -p at.magixfly.coretracker -c android.intent.category.LAUNCHER 1 >/dev/null 2>&1
sleep 25
