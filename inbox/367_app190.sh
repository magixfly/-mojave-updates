# App 1.90: WLAN-Formular auf der Fernsteuer-Seite (Port 8090)
touch /tmp/claude_remote
B=$(adb devices | awk '/:5555[[:space:]]+device/{print $1; exit}'); echo "Box $B"
adb -s $B install -r apk/CoreTracker.apk 2>&1 | tail -1
adb -s $B shell dumpsys package at.magixfly.coretracker | grep -m1 versionName
adb -s $B shell am start -n at.magixfly.coretracker/.MainActivity >/dev/null 2>&1
sleep 15
curl -s -m 5 http://${B%:*}:8090/ | grep -o "WLAN eintragen" | head -1
