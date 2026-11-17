#nobox
for i in 1 2 3 4 5 6; do r=$(curl -s -m 5 http://127.0.0.1:8080/api/devices); echo "$r" | python3 -c "import sys,json;d=json.load(sys.stdin);print(i if False else '', 'busy',d['busy'],'prog',d['prog'])" 2>/dev/null; echo "$r" | grep -q '"busy": false' && break; sleep 10; done
echo "$r" | python3 -c "import sys,json;d=json.load(sys.stdin)['d'];[print(k, json.dumps(v)[:180]) for k,v in d.items()]"
echo "--- Box-App postet an Tracker?"; adb logcat -d -t 2000 | grep -iE 'api/box|coretracker' | tail -5 | cut -c1-160
adb shell cat /data/data/at.magixfly.coretracker/shared_prefs/ct.xml 2>/dev/null | grep -iE 'host|pi' | head -5
