#nobox
# Pi im Box-Hotspot: ADB 5555 offen? Warum nicht? Temperatur
. ~/adbx/env.sh 2>/dev/null
nmcli -t -f ACTIVE,SSID,FREQ dev wifi | grep '^yes'; GW=$(ip route | awk '/^default/{print $3; exit}'); echo "GW $GW"
ping -c2 -W1 $GW >/dev/null && echo ping ok
nc -zv -w2 $GW 5555 2>&1 | tail -1
adb connect $GW:5555 2>&1 | tail -1
adb -s $GW:5555 shell "settings get global adb_enabled; getprop persist.adb.tcp.port; getprop service.adb.tcp.port; getprop init.svc.adbd; logcat -d | grep CTAP | tail -4; cat /sys/class/thermal/thermal_zone0/temp" 2>&1 | head -12
