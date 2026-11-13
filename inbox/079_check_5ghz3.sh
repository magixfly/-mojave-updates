#screenshot
# Prüfen: alle im 5-GHz-Hotspot?
cat /sys/module/cfg80211/parameters/ieee80211_regdom
nmcli -f IN-USE,SSID,CHAN,FREQ,SIGNAL dev wifi list 2>&1 | grep '^\*'
printf "CosmoStreamer 172.20.10.2: "; curl -s -m 3 -o /dev/null -w "%{http_code} %{time_total}s" http://172.20.10.2/; echo
echo "Box:"; adb shell "ip -o -4 addr show wlan0; dumpsys wifi | grep -m1 -i 'mWifiInfo'" 2>&1 | cut -c1-260
