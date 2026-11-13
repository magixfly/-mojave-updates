#screenshot
# App 1.39: Box-Hotspot nach Start automatisch (über lokales ADB); hier nur Verbindungstest, kein Umschalten
adb push apk/CoreTracker.apk /sdcard/Download/coretracker.apk >/dev/null
S=$(adb shell stat -c %s /sdcard/Download/coretracker.apk | tr -d '\r')
adb shell "cat /sdcard/Download/coretracker.apk | pm install -r -S $S"
adb shell dumpsys package at.magixfly.coretracker | grep versionName
adb shell logcat -c
adb shell am force-stop at.magixfly.coretracker; sleep 1
adb shell am start -n at.magixfly.coretracker/.MainActivity --ez adbtest true >/dev/null; sleep 12
adb shell logcat -d | grep CTAP | cut -c19- | tail -8
