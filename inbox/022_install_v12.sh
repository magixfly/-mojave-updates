#screenshot
# Core-Tracker-App V1.2 installieren und starten
adb push apk/CoreTracker.apk /sdcard/Download/coretracker.apk >/dev/null
S=$(adb shell stat -c %s /sdcard/Download/coretracker.apk | tr -d '\r')
adb shell "cat /sdcard/Download/coretracker.apk | pm install -r -S $S"
adb shell dumpsys package at.magixfly.coretracker | grep -m2 -E 'versionName|targetSdk'
adb shell monkey -p at.magixfly.coretracker -c android.intent.category.LAUNCHER 1 >/dev/null 2>&1
sleep 15
adb logcat -d -t 600 | grep -iE 'coretracker|AndroidRuntime' | tail -12
