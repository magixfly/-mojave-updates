# App 1.75: FPV-Player-Auswahl, Hänger-Messung, Menü „Restart app / Close app“
adb install -r apk/CoreTracker.apk 2>&1 | tail -1
adb shell dumpsys package at.magixfly.coretracker | grep -m1 versionName
adb logcat -c
adb shell am start -n at.magixfly.coretracker/.MainActivity >/dev/null 2>&1
sleep 75
adb logcat -d -s CTFPV:D | grep -E "CTSTAT|stat:|FPVSTATE" | tail -6
#screenshot
