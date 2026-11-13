#screenshot
# FPV-Diagnose: Split öffnen, 45 s Konsole der CosmoStreamer-Seite mitschreiben
adb shell logcat -c
adb shell input keyevent 4; sleep 2
adb shell input tap 114 681; sleep 45
adb exec-out screencap -p > outbox/083_split.png
adb shell logcat -d | grep CTFPV | grep -v slider | cut -c19- | tail -40
echo "--- Janus Streams:"; S=$(curl -s -m 3 -X POST -d '{"janus":"create","transaction":"a"}' http://172.20.10.2:8088/janus | python3 -c 'import sys,json;print(json.load(sys.stdin)["data"]["id"])' 2>/dev/null); echo "session $S"
H=$(curl -s -m 3 -X POST -d '{"janus":"attach","plugin":"janus.plugin.streaming","transaction":"b"}' http://172.20.10.2:8088/janus/$S | python3 -c 'import sys,json;print(json.load(sys.stdin)["data"]["id"])' 2>/dev/null)
curl -s -m 3 -X POST -d '{"janus":"message","transaction":"c","body":{"request":"list"}}' http://172.20.10.2:8088/janus/$S/$H | head -c 1200; echo
