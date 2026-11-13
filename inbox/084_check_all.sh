#screenshot
# Stand nach Neustart: Netz, CosmoStreamer, Janus-Video, FPV in der App
nmcli -f IN-USE,SSID,CHAN,FREQ dev wifi list 2>&1 | grep '^\*'; ip route | awk '/^default/{print "Gateway",$3}'
C=""; for h in 172.20.10.2 cosmostreamer.local $(ip route | awk '/^default/{print $3; exit}' | sed 's/\.[0-9]*$//').{2..20}; do curl -s -m 1 http://$h/ 2>/dev/null | grep -qi '<title>cosmostreamer' && { C=$h; break; }; done; echo "CosmoStreamer: ${C:-nicht gefunden}"
if [ -n "$C" ]; then S=$(curl -s -m 3 -X POST -d '{"janus":"create","transaction":"a"}' http://$C:8088/janus | python3 -c 'import sys,json;print(json.load(sys.stdin)["data"]["id"])' 2>/dev/null)
H=$(curl -s -m 3 -X POST -d '{"janus":"attach","plugin":"janus.plugin.streaming","transaction":"b"}' http://$C:8088/janus/$S | python3 -c 'import sys,json;print(json.load(sys.stdin)["data"]["id"])' 2>/dev/null)
curl -s -m 3 -X POST -d '{"janus":"message","transaction":"c","body":{"request":"list"}}' http://$C:8088/janus/$S/$H | python3 -c 'import sys,json;l=json.load(sys.stdin)["plugindata"]["data"]["list"];[print("Janus",s["id"],m["mid"],"age",m.get("age_ms"),"ms") for s in l for m in s.get("media",[]) if m["type"]=="video"]' 2>&1 | head -4; fi
adb shell logcat -c; adb shell input keyevent 4; sleep 2; adb shell input tap 114 681; sleep 40
adb exec-out screencap -p > outbox/084_split.png
adb shell logcat -d | grep CTFPV | grep -v slider | cut -c19- | tail -15
