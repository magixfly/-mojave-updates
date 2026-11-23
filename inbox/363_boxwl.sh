touch /tmp/claude_remote
B=$(adb devices | awk '/:5555[[:space:]]+device/{print $1; exit}'); echo "Box $B"
adb -s $B shell 'cat /data/local/tmp/wl.log; echo ==; cmd wifi status | grep -m1 "connected to"; cmd wifi list-networks; echo == Log; logcat -d -s CTWL CTAP | tail -15'
