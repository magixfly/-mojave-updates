#nobox
curl -s localhost:8080/api/state | python3 -c "import json,sys;d=json.load(sys.stdin);print(d.get(\"hw\"),d.get(\"me\"))"
sleep 30
curl -s localhost:8080/api/state | python3 -c "import json,sys;d=json.load(sys.stdin);print(d.get(\"hw\"),d.get(\"me\"))"
