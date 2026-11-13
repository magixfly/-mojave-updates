#screenshot
# Tracker am Pi auf 2.0.31 aktualisieren, App 1.7 installieren
curl -s -X POST -H 'Content-Type: application/json' -d '{"check":1}' http://127.0.0.1:8080/api/update; echo
sleep 8
curl -s -X POST -H 'Content-Type: application/json' -d '{"install":1}' http://127.0.0.1:8080/api/update; echo
for i in $(seq 1 30); do sleep 3; v=$(curl -s http://127.0.0.1:8080/api/update 2>/dev/null); case "$v" in *'"cur": "2.0.31"'*|*'"cur":"2.0.31"'*) echo "Tracker 2.0.31 läuft"; break;; esac; done
echo "$v" | cut -c1-200
adb push apk/CoreTracker.apk /sdcard/Download/coretracker.apk >/dev/null
S=$(adb shell stat -c %s /sdcard/Download/coretracker.apk | tr -d '\r')
adb shell "cat /sdcard/Download/coretracker.apk | pm install -r -S $S"
adb shell monkey -p at.magixfly.coretracker -c android.intent.category.LAUNCHER 1 >/dev/null 2>&1
sleep 25
