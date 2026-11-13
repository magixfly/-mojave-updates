#screenshot
# Box sofort zurück zur Karte
adb shell input keyevent 4; sleep 2
echo "--- Port 80 am Tracker-Pi:"; curl -s -m 2 http://127.0.0.1/ | grep -io '<title>[^<]*' | head -1; curl -s -m 2 http://127.0.0.1/ | grep -io '.\{40\}cosmostreamer.\{40\}' | head -3
