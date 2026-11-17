# App 1.68: Split-Knoepfe so breit wie die Spalte
adb install -r apk/CoreTracker.apk 2>&1 | tail -1
adb shell am start -n at.magixfly.coretracker/.MainActivity >/dev/null 2>&1
sleep 45
#screenshot
