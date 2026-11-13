#screenshot
# App 1.32: Splitscreen (Karte links, FPV rechts); Taste links unten
adb push apk/CoreTracker.apk /sdcard/Download/coretracker.apk >/dev/null
S=$(adb shell stat -c %s /sdcard/Download/coretracker.apk | tr -d '\r')
adb shell "cat /sdcard/Download/coretracker.apk | pm install -r -S $S"
adb shell dumpsys package at.magixfly.coretracker | grep versionName
adb shell am force-stop at.magixfly.coretracker; sleep 1
adb shell monkey -p at.magixfly.coretracker -c android.intent.category.LAUNCHER 1 >/dev/null 2>&1
sleep 35
adb exec-out screencap -p > outbox/067_1_karte.png
adb shell input tap 114 674; sleep 15
adb exec-out screencap -p > outbox/067_2_split.png
adb shell input tap 114 674; sleep 2; adb shell input tap 114 674; sleep 2; adb shell input tap 114 674; sleep 3
