#screenshot
getprop service.adb.tcp.port; getprop ro.build.version.sdk
echo "== top"; top -b -n 2 -d 2 -m 10 | tail -14
echo "== load"; cat /proc/loadavg
echo "== mem"; free -m | head -3
echo "== dns"; S=$(date +%s%N); ping -c1 -W3 basemap.at >/dev/null 2>&1; E=$(date +%s%N); echo "ping basemap.at $(( (E-S)/1000000 )) ms"
echo "== log"; logcat -d -t 1500 | grep -iE "console|Choreographer|ANR|Skipped|chromium" | tail -25
