#screenshot
dumpsys package at.magixfly.coretracker | grep -m1 versionName
pidof at.magixfly.coretracker && echo app laeuft
am start -n at.magixfly.coretracker/.MainActivity >/dev/null 2>&1; sleep 8
dumpsys location | grep -iE "provider|at.magixfly" | head -12
dumpsys package at.magixfly.coretracker | grep -E "ACCESS_(FINE|COARSE)_LOCATION: granted" | head -2
logcat -d -t 400 | grep -E "CTAP|CTGPS|AndroidRuntime|FATAL" | tail -20
pgrep -f boxmai[n].py || echo "kein Box-Tracker-Prozess"
du -sh /data/local/tmp/ct 2>/dev/null
du -sh /data/data/at.magixfly.coretracker/files/tiles /data/data/at.magixfly.coretracker/files/ovl 2>/dev/null
