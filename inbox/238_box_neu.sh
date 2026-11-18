adb logcat -d | grep -i "console\|Uncaught\|chromium" | tail -12
adb shell am force-stop at.magixfly.coretracker; sleep 2
adb shell am start -n at.magixfly.coretracker/.MainActivity >/dev/null 2>&1; sleep 30
#screenshot
