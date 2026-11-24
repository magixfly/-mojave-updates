#screenshot
for i in $(seq 1 40); do dumpsys package at.magixfly.coretracker | grep -q "versionName=2.06" && break; sleep 10; done
dumpsys package at.magixfly.coretracker | grep -m1 versionName
sleep 45
pidof at.magixfly.coretracker && echo app laeuft
dumpsys package at.magixfly.coretracker | grep -E "BLUETOOTH_(SCAN|CONNECT): granted" | head -2
settings get global bluetooth_on
logcat -d -t 2000 | grep -E "CTBLE|CTAP|AndroidRuntime|FATAL" | tail -25
ls -la /data/data/at.magixfly.coretracker/files/gebiete.json 2>&1
df -h /data | tail -1
