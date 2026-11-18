# App 1.74: im Hintergrund Karte/Video pausieren
adb install -r apk/CoreTracker.apk 2>&1 | tail -1
adb shell am start -n at.magixfly.coretracker/.MainActivity >/dev/null 2>&1
sleep 30
#screenshot
