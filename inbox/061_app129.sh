#screenshot
# App 1.29: FPV mit Diagnose (Konsole -> logcat CTFPV)
adb push apk/CoreTracker.apk /sdcard/Download/coretracker.apk >/dev/null
S=$(adb shell stat -c %s /sdcard/Download/coretracker.apk | tr -d '\r')
adb shell "cat /sdcard/Download/coretracker.apk | pm install -r -S $S"
adb shell dumpsys package at.magixfly.coretracker | grep versionName
adb shell logcat -c
adb shell am force-stop at.magixfly.coretracker; sleep 1
adb shell monkey -p at.magixfly.coretracker -c android.intent.category.LAUNCHER 1 >/dev/null 2>&1
sleep 25
adb shell input tap 1860 360; sleep 25
adb exec-out screencap -p > outbox/061_2_fpv.png
adb shell logcat -d | grep -E "CTFPV|chromium" | tail -60
adb shell input tap 1860 360; sleep 2; adb shell input tap 1860 360; sleep 3
