# Test: App schaltet Hotspot per Bedienungshilfe ein
adb shell logcat -c
adb shell am start -n at.magixfly.coretracker/.MainActivity --ez aptest true >/dev/null
sleep 6; adb exec-out screencap -p > outbox/116_a.png 2>/dev/null
adb shell logcat -d | grep CTAP | tail -5
sleep 4; adb shell "dumpsys tethering | grep -c TetheredState" 2>&1
