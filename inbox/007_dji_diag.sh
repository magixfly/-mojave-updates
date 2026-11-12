#screenshot
# Diagnose: Bluetooth, Standort, Berechtigungen von DJI Fly
echo "BT an: $(adb shell settings get global bluetooth_on)"
echo "Standort-Modus: $(adb shell settings get secure location_mode)"
adb shell cmd location is-location-enabled
adb shell dumpsys package dji.go.v5 | grep -E 'permission\.(ACCESS_FINE|ACCESS_COARSE|BLUETOOTH_SCAN|BLUETOOTH_CONNECT|NEARBY_WIFI|ACCESS_BACKGROUND)' | sort -u
adb shell dumpsys bluetooth_manager | grep -iE 'enabled|state:|ConnectionState' | head -6
adb shell dumpsys wifi | grep -m3 -E 'mWifiInfo|SSID'
