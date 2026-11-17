adb logcat -d | grep -i "CTFPV\|fpv" | tail -15
adb shell ping -c 2 -W 1 192.168.178.159 | tail -2
curl -s -m 4 http://192.168.178.159/ | grep -io "<title>[^<]*" | head -1
