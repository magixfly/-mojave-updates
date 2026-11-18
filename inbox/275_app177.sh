# App 1.77: Jmuxer nah an live
adb install -r apk/CoreTracker.apk 2>&1 | tail -1
adb shell dumpsys package at.magixfly.coretracker | grep -m1 versionName
adb shell am start -n at.magixfly.coretracker/.MainActivity >/dev/null 2>&1
#screenshot
sleep 20
