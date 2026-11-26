#screenshot
echo "== props"; getprop persist.adb.tcp.port; getprop service.adb.tcp.port; settings get global adb_wifi_enabled
echo "== top"; top -b -n 1 -m 12 | head -22
echo "== load"; cat /proc/loadavg
echo "== mem"; dumpsys meminfo at.magixfly.coretracker | grep -E "TOTAL|Native Heap|Dalvik Heap" | head -4
free -m 2>/dev/null | head -3
echo "== log"; logcat -d -t 600 | grep -iE "chromium|Choreographer|ANR|coretracker|console" | tail -30
setprop persist.adb.tcp.port 5555
setprop service.adb.tcp.port 5555
setsid sh -c 'sleep 25; setprop ctl.restart adbd' </dev/null >/dev/null 2>&1 &
