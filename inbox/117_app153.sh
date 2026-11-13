# App 1.53: Hotspot-Schalter in der Zeile von „WLAN-Hotspot“ suchen (mit Protokoll), dann Test
adb push apk/CoreTracker.apk /sdcard/Download/coretracker.apk >/dev/null
S=$(adb shell stat -c %s /sdcard/Download/coretracker.apk | tr -d '\r')
adb shell "cat /sdcard/Download/coretracker.apk | pm install -r -S $S"
adb shell dumpsys package at.magixfly.coretracker | grep versionName
adb shell settings get secure enabled_accessibility_services
adb shell logcat -c; adb shell am force-stop at.magixfly.coretracker; sleep 1
adb shell am start -n at.magixfly.coretracker/.MainActivity --ez aptest true >/dev/null
sleep 8; adb exec-out screencap -p > outbox/117_a.png 2>/dev/null
adb shell logcat -d | grep CTAP | cut -c19- | tail -10
