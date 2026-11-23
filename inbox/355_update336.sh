#nobox
# 23.11.: Tracker-Update auf 3.36 (Heimposition ohne GPS-Fix), danach Zustand
touch /tmp/claude_remote
sleep 240
curl -s -X POST -H 'Content-Type: application/json' -d '{"check":1}' localhost:8080/api/update; echo
curl -s -X POST -H 'Content-Type: application/json' -d '{"install":1}' localhost:8080/api/update; echo
for i in $(seq 1 30); do sleep 3; v=$(curl -s -m 2 localhost:8080/api/state | python3 -c "import json,sys;print(json.load(sys.stdin).get('ver'))" 2>/dev/null); [ "$v" = "3.36" ] && break; done
sleep 8
curl -s localhost:8080/api/state | python3 -c "import json,sys;d=json.load(sys.stdin);print('ver',d.get('ver'),'me',d.get('me'),'wifi',d.get('wifi'))"
