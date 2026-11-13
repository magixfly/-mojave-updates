#nobox
# Box im Heimnetz? ADB 5555? Hotspot an? Temperatur
. ~/adbx/env.sh 2>/dev/null
for h in 192.168.178.235; do ping -c2 -W1 $h >/dev/null && echo "$h ping ok" || echo "$h kein ping"; adb connect $h:5555 2>&1 | tail -1; done
nmcli -f SSID,CHAN,FREQ,SIGNAL dev wifi list 2>&1 | grep -E "XVII|box" 
adb -s 192.168.178.235:5555 shell "dumpsys tethering | grep -c TetheredState; settings get global adb_enabled; logcat -d | grep CTAP | tail -3; for z in /sys/class/thermal/thermal_zone*/temp; do cat \$z; done | head -4; top -b -n1 | head -12" 2>&1 | cut -c1-150
