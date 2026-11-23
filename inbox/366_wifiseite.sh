# WLAN-Einstellungen der Box öffnen (User tippt Media-Passwort selbst)
touch /tmp/claude_remote
B=$(adb devices | awk '/:5555[[:space:]]+device/{print $1; exit}'); echo "Box $B"
adb -s $B shell am start -a android.settings.WIFI_SETTINGS 2>&1 | tail -1
sleep 4
adb -s $B shell dumpsys activity activities | grep -m2 -E "topResumedActivity|mResumedActivity"
adb -s $B exec-out screencap -p > outbox/366_wifiseite.png
