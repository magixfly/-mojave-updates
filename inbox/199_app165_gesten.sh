# App 1.65 Fix 2: Bedienungshilfe darf tippen (canPerformGestures)
adb install -r apk/CoreTracker.apk 2>&1 | tail -1
S=$(adb shell settings get secure enabled_accessibility_services | tr -d '\r'); echo "a11y: $S"
adb shell settings put secure enabled_accessibility_services "$(echo "$S" | sed 's#:*at.magixfly.coretracker/at.magixfly.coretracker.A11y##')"; sleep 2
adb shell settings put secure enabled_accessibility_services "$S"; adb shell settings put secure accessibility_enabled 1; sleep 3
adb shell am start -n at.magixfly.coretracker/.MainActivity >/dev/null 2>&1; sleep 15
adb shell dumpsys accessibility | grep -i -m3 "coretracker"
echo "tap: $(curl -s -m 5 'http://192.168.178.235:8090/tap?x=130&y=677')"; sleep 4
#screenshot
