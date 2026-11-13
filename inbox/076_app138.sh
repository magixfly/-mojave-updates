#screenshot
# App 1.38: kurze Maps-Texte, Download pausiert im iPhone-Hotspot (mobile Daten)
adb push apk/CoreTracker.apk /sdcard/Download/coretracker.apk >/dev/null
S=$(adb shell stat -c %s /sdcard/Download/coretracker.apk | tr -d '\r')
adb shell "cat /sdcard/Download/coretracker.apk | pm install -r -S $S"
adb shell dumpsys package at.magixfly.coretracker | grep versionName
adb shell am force-stop at.magixfly.coretracker; sleep 1
adb shell monkey -p at.magixfly.coretracker -c android.intent.category.LAUNCHER 1 >/dev/null 2>&1
echo "--- ESP am Pi:"; ls -l /dev/serial/by-id/ 2>&1; ls /dev/ttyUSB* /dev/ttyACM* 2>&1
uptime; systemctl --user list-units 2>/dev/null | grep -i -E "track|core" ; systemctl list-units 2>/dev/null | grep -i -E "track|core" | head
ps aux | grep -iE "tracker|python" | grep -v grep | head -5
journalctl -b --no-pager 2>/dev/null | grep -iE "ttyUSB|ttyACM|cp210|ch34|usb 1-1" | head -20
sleep 25
