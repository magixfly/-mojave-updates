# App 1.70: PiP-Groesse per Ecke ziehen
adb install -r apk/CoreTracker.apk 2>&1 | tail -1
adb shell am start -n at.magixfly.coretracker/.MainActivity >/dev/null 2>&1
sleep 45
#screenshot
