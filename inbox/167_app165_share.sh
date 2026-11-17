#screenshot
# App 1.65 installieren: Box-Bildschirm im Browser (Port 8090), dann testen
adb install -r apk/CoreTracker.apk 2>&1 | tail -1
adb shell dumpsys package at.magixfly.coretracker | grep -m1 versionName
adb shell am start -n at.magixfly.coretracker/.MainActivity >/dev/null 2>&1
sleep 20
B=$(adb shell ip -4 addr show wlan0 | grep -o 'inet [0-9.]*' | cut -d' ' -f2 | tr -d '\r'); echo "Box-IP: $B"
curl -s -m 5 "http://$B:8090/state"; echo
curl -s -m 5 -o /dev/null "http://$B:8090/shot.jpg"
for i in 1 2 3 4 5 6 7 8; do sleep 4; r=$(curl -s -m 5 "http://$B:8090/state"); echo "$r"; echo "$r" | grep -q '"run":true' && break; done
sleep 3; curl -s -m 5 -o outbox/167_share.png "http://$B:8090/shot.jpg"; ls -la outbox/167_share.png; file outbox/167_share.png
curl -s -m 5 "http://$B:8090/" | head -c 120; echo
adb shell logcat -d -s CTSS:D | tail -15
adb shell am start -n at.magixfly.coretracker/.MainActivity >/dev/null 2>&1; sleep 3
