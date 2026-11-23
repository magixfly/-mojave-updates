#nobox
# 23.11.: Versionen Tracker / Core / Navi / ESP prüfen
touch /tmp/claude_remote
echo "== Tracker"; curl -s localhost:8080/api/state | python3 -c "import json,sys;d=json.load(sys.stdin);print('ver',d.get('ver'),'esp',(d.get('hw') or {}).get('fw'),'src',d.get('src'))"
curl -s localhost:8080/api/update | head -c 400; echo
echo "== Core"; for h in mojave.local 192.168.178.213; do r=$(curl -s -m 4 http://$h/api/online); [ -n "$r" ] && { echo "$h: $r" | head -c 600; echo; break; }; done
curl -s -m 4 http://mojave.local/api/sys | python3 -c "import json,sys;d=json.load(sys.stdin);print('fw',d.get('fw'),'up',d.get('up'),'reset',d.get('reset'))" 2>&1 | tail -1
echo "== Navi"; curl -s localhost:8080/api/devices | python3 -c "import json,sys;d=json.load(sys.stdin)['d'] or {};print({k:(v.get('ver'),v.get('ip'),v.get('ok')) for k,v in d.items()})" 2>&1 | tail -1
