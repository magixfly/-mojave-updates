# App 1.91 (Fernwartung direkt auf der Box) installieren, sobald die Box im selben Netz ist
touch /tmp/claude_remote
B=$(adb devices | awk '/:5555[[:space:]]+device/{print $1; exit}'); echo "Box $B"
adb -s $B install -r apk/CoreTracker.apk 2>&1 | tail -1
adb -s $B shell dumpsys package at.magixfly.coretracker | grep -m1 versionName
adb -s $B shell am start -n at.magixfly.coretracker/.MainActivity >/dev/null 2>&1
