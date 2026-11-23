# App 1.89: WLAN mit falschem Passwort überspringen; Media (falsches Passwort aus Test) wieder vergessen
touch /tmp/claude_remote
B=$(adb devices | awk '/:5555[[:space:]]+device/{print $1; exit}'); echo "Box $B"
adb -s $B shell 'id=$(cmd wifi list-networks | awk "\$2==\"Media\"{print \$1; exit}"); [ -n "$id" ] && cmd wifi forget-network $id; cmd wifi list-networks'
adb -s $B install -r apk/CoreTracker.apk 2>&1 | tail -1
adb -s $B shell dumpsys package at.magixfly.coretracker | grep -m1 versionName
adb -s $B shell am start -n at.magixfly.coretracker/.MainActivity >/dev/null 2>&1
adb -s $B shell 'rm -f /data/local/tmp/wl.log; cmd wifi status | grep -m1 "connected to"'
