#screenshot
# APK umbenennen (Klammern im Namen stören) und installieren
adb shell 'for f in /sdcard/Download/*DJIFly*.apk; do mv "$f" /sdcard/Download/djifly.apk; done'
S=$(adb shell stat -c %s /sdcard/Download/djifly.apk | tr -d '\r'); echo "Größe: $S"
adb shell "cat /sdcard/Download/djifly.apk | pm install -r -S $S"
adb shell dumpsys package dji.go.v5 | grep -m1 versionName
adb shell monkey -p dji.go.v5 -c android.intent.category.LAUNCHER 1 >/dev/null 2>&1; sleep 12
