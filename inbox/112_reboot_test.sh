#nobox
# Neustart-Test Box: Hotspot von selbst an? ADB 5555 erreichbar? (wartet bis 4 min)
for i in $(seq 1 24); do GW=$(ip route | awk '/^default/{print $3; exit}'); S=$(nmcli -t -f ACTIVE,SSID,FREQ dev wifi | grep '^yes'); echo "$(date +%T) $S gw=$GW"; 
  . ~/adbx/env.sh 2>/dev/null; if adb connect $GW:5555 2>&1 | grep -q connected; then echo "ADB OK an $GW"; adb -s $GW:5555 shell "dumpsys tethering | grep -c TetheredState; settings get global adb_enabled; getprop sys.boot_completed; logcat -d | grep CTAP | tail -3"; break; fi; sleep 10; done
