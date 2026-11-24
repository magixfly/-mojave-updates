#screenshot
dumpsys package at.magixfly.coretracker | grep -m1 versionName
pidof at.magixfly.coretracker && echo app laeuft
dumpsys package at.magixfly.coretracker | grep -E "BLUETOOTH_(SCAN|CONNECT): granted" | head -2
settings get global bluetooth_on
logcat -d -t 4000 | grep -E "CTBLE|CTAP|AndroidRuntime|FATAL" | tail -30
ls -la /data/data/at.magixfly.coretracker/files/gebiete.json 2>&1
head -c 300 /data/data/at.magixfly.coretracker/files/gebiete.json; echo
grep -o '"areasCleaned"[^/]*/[0-9]*\|tileCount[^/]*' /data/data/at.magixfly.coretracker/shared_prefs/ct.xml
du -sh /data/data/at.magixfly.coretracker/files/tiles 2>/dev/null
df -h /data | tail -1
