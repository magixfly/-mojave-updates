# Alle Funknetze XVII (2,4 und 5 GHz?) – frischer Scan
nmcli dev wifi rescan 2>&1; sleep 6
nmcli -f IN-USE,SSID,BSSID,CHAN,FREQ,SIGNAL dev wifi list 2>&1 | grep -E "XVII|IN-USE"
adb shell "dumpsys wifi | grep -m1 mWifiInfo" 2>/dev/null | grep -oE "Frequency: [0-9]+|Wi-Fi standard: [^,]+|Link speed: [^,]+"
