#screenshot
# App 1.34: Split 1:2,5; FPV-Taste links unten, Lage-/GPS-Zeile oben in der Kopfzeile
adb push apk/CoreTracker.apk /sdcard/Download/coretracker.apk >/dev/null
S=$(adb shell stat -c %s /sdcard/Download/coretracker.apk | tr -d '\r')
adb shell "cat /sdcard/Download/coretracker.apk | pm install -r -S $S"
adb shell dumpsys package at.magixfly.coretracker | grep versionName
adb shell am force-stop at.magixfly.coretracker; sleep 1
adb shell monkey -p at.magixfly.coretracker -c android.intent.category.LAUNCHER 1 >/dev/null 2>&1
sleep 40
