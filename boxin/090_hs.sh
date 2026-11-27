#screenshot
dumpsys tethering 2>/dev/null | grep -iE "wlan|Tethered|state" | head -10
cmd wifi status 2>/dev/null | head -5
dumpsys window | grep -m1 mCurrentFocus
logcat -d -t 3000 | grep -iE "CTHS|Hotspot|tether" | tail -15
