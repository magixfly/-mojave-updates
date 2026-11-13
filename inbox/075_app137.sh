#screenshot
# App 1.37: Bild-im-Bild ziehen/doppeltippen, keine Meldungsfenster der CosmoStreamer-Seite
adb push apk/CoreTracker.apk /sdcard/Download/coretracker.apk >/dev/null
S=$(adb shell stat -c %s /sdcard/Download/coretracker.apk | tr -d '\r')
adb shell "cat /sdcard/Download/coretracker.apk | pm install -r -S $S"
adb shell dumpsys package at.magixfly.coretracker | grep versionName
adb shell am force-stop at.magixfly.coretracker; sleep 1
adb shell monkey -p at.magixfly.coretracker -c android.intent.category.LAUNCHER 1 >/dev/null 2>&1
sleep 30
nmcli -f IN-USE,SSID,CHAN,FREQ dev wifi list 2>&1 | grep '^\*'
printf "CosmoStreamer 172.20.10.2: "; curl -s -m 3 http://172.20.10.2/ | grep -io '<title>[^<]*' | head -1; echo
