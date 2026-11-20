#nobox
for i in $(seq 1 6); do curl -s -X POST -H "Content-Type: application/json" -d "{\"check\":1}" http://127.0.0.1:8080/api/update >/dev/null; sleep 10; curl -s -X POST -H "Content-Type: application/json" -d "{\"install\":1}" http://127.0.0.1:8080/api/update >/dev/null; for k in $(seq 1 20); do sleep 3; curl -s --max-time 2 http://127.0.0.1:8080/api/state | head -c 30 | grep -q "\"3.33\"" && { echo "3.33 läuft"; break 2; }; done; sleep 20; done
sleep 40; curl -s localhost:8080/api/state | python3 -c "import json,sys;d=json.load(sys.stdin);print(d.get(\"hw\"),d.get(\"me\"))"
