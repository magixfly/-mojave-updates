#screenshot
# App 1.65 Fix: Manifest foregroundServiceType=mediaProjection (Bildschirm-Uebertragung stuerzte ab)
adb install -r apk/CoreTracker.apk 2>&1 | tail -1
adb shell am start -n at.magixfly.coretracker/.MainActivity >/dev/null 2>&1
sleep 15
adb shell dumpsys package at.magixfly.coretracker | grep -i -m3 "foregroundServiceType\|versionName"
