dumpsys package at.magixfly.coretracker | grep -m1 versionName
cmd wifi get-country-code
cmd wifi status | grep -m1 -o 'BSSID: [0-9a-f:]*.*RSSI: -[0-9]*'
wpa_cli -i wlan0 scan; sleep 8; wpa_cli -i wlan0 scan_results | grep -iE "bssid|Media"
logcat -d | grep CTWLAN | tail -5
