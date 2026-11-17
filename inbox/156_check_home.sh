#nobox
#screenshot
# Erreichbarkeit im Heimnetz: Pi, Box, CosmoStreamer
echo "Pi: $(hostname -I | cut -d' ' -f1) WLAN=$(iwgetid -r)"
echo "Box: $(adb devices | grep -c 'device$') ADB-Gerät(e)"; adb shell getprop ro.build.version.release 2>&1 | head -1
for h in cosmostreamer.local 192.168.178.175; do printf "%s: " $h; ping -c1 -W2 $h 2>&1 | grep -oE 'time=[0-9.]+ ms|unknown host|100% packet loss' | head -1; done
curl -s -m 5 http://192.168.178.175/ | grep -o '<title>[^<]*' | head -1
curl -s -m 3 http://127.0.0.1:8080/api/update | cut -c1-90
