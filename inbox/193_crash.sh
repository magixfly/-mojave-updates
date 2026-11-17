#screenshot
adb logcat -d -b crash | tail -40
adb shell input tap 700 445; sleep 2
adb shell monkey -p at.magixfly.coretracker -c android.intent.category.LAUNCHER 1 >/dev/null 2>&1; sleep 12
adb shell pidof at.magixfly.coretracker
