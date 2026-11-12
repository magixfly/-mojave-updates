#screenshot
# DJI-Fly-Log rund um den Verbindungsversuch
P=$(adb shell pidof dji.go.v5 | tr -d '\r'); echo "PID: $P"
adb logcat -d -t 20000 | grep -iE 'goggle|57FE|wifiNetworkSpecifier|NetworkRequest|ble|gatt|connect.*fail|liveview|share' | grep -viE 'LOWI|bluetooth_manager' | tail -60
echo "--- WLAN-Verlauf ---"
adb shell dumpsys wifi | grep -iE 'DJI-GOGGLES|NetworkSpecifier|onUnavailable|requestNetwork' | tail -15
