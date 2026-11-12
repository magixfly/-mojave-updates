#screenshot
# Core-Tracker-App installieren und starten
adb install -r apk/CoreTracker.apk
adb shell monkey -p at.magixfly.coretracker -c android.intent.category.LAUNCHER 1 >/dev/null 2>&1
sleep 15
adb logcat -d -t 400 | grep -iE 'coretracker|AndroidRuntime' | tail -15
