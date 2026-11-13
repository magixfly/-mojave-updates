#screenshot
# App 1.27: optionale FPV-Taste (CosmoStreamer, WebRTC Janus) – Karte -> FPV -> Bild-im-Bild -> Karte
adb push apk/CoreTracker.apk /sdcard/Download/coretracker.apk >/dev/null
S=$(adb shell stat -c %s /sdcard/Download/coretracker.apk | tr -d '\r')
adb shell "cat /sdcard/Download/coretracker.apk | pm install -r -S $S"
adb shell dumpsys package at.magixfly.coretracker | grep versionName
adb shell am force-stop at.magixfly.coretracker; sleep 1
adb shell monkey -p at.magixfly.coretracker -c android.intent.category.LAUNCHER 1 >/dev/null 2>&1
sleep 30
adb exec-out screencap -p > outbox/058_1_karte.png
adb shell input tap 1860 360; sleep 25
adb exec-out screencap -p > outbox/058_2_fpv.png
adb shell input tap 1860 360; sleep 8
adb exec-out screencap -p > outbox/058_3_pip.png
adb shell input tap 1860 360; sleep 3
adb shell logcat -d -t 300 | grep -iE "chromium|coretracker|webrtc" | tail -25
