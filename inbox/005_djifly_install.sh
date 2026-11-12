#screenshot
# heruntergeladene DJI-Fly-APK auf der Box installieren
adb shell 'ls -la /sdcard/Download/ | tail -5'
F=$(adb shell 'ls -t /sdcard/Download/*.apk 2>/dev/null | head -1' | tr -d '\r')
echo "APK: $F"
if adb shell pm list packages | grep -q dji.go.v5; then echo "DJI Fly schon installiert"
elif [ -n "$F" ]; then
  S=$(adb shell stat -c %s "$F" | tr -d '\r'); echo "Größe: $S"
  adb shell "cat '$F' | pm install -r -S $S"
fi
adb shell dumpsys package dji.go.v5 | grep -m1 versionName
adb shell monkey -p dji.go.v5 -c android.intent.category.LAUNCHER 1 >/dev/null 2>&1; sleep 10
