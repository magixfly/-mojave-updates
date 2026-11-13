#screenshot
# App 1.30: FPV zeigt Verbindungsstatus, wechselt Janus/Jmuxer bis Bild kommt
adb push apk/CoreTracker.apk /sdcard/Download/coretracker.apk >/dev/null
S=$(adb shell stat -c %s /sdcard/Download/coretracker.apk | tr -d '\r')
adb shell "cat /sdcard/Download/coretracker.apk | pm install -r -S $S"
adb shell dumpsys package at.magixfly.coretracker | grep versionName
adb shell logcat -c
adb shell am force-stop at.magixfly.coretracker; sleep 1
adb shell monkey -p at.magixfly.coretracker -c android.intent.category.LAUNCHER 1 >/dev/null 2>&1
sleep 25
adb shell input tap 1860 360; sleep 20
adb exec-out screencap -p > outbox/062_2_fpv.png
adb shell logcat -d | grep -E "CTFPV" | grep -v slider | tail -15
adb shell input tap 1860 360; sleep 2; adb shell input tap 1860 360; sleep 3
