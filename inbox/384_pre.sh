#nobox
curl -s localhost:8080/api/state | python3 -c "import json,sys;d=json.load(sys.stdin);print(d.get(\"ver\"),d.get(\"autopre\"))"
grep -a autopre ~/Bodenstation/server.log 2>/dev/null | tail -3
