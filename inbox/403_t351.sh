#nobox
for i in $(seq 1 6); do curl -s -X POST -H "Content-Type: application/json" -d "{\"check\":1}" http://127.0.0.1:8080/api/update >/dev/null; sleep 10; curl -s -X POST -H "Content-Type: application/json" -d "{\"install\":1}" http://127.0.0.1:8080/api/update >/dev/null; for k in $(seq 1 20); do sleep 3; curl -s --max-time 2 http://127.0.0.1:8080/api/state | head -c 30 | grep -q "\"3.51\"" && { echo "3.51 läuft"; break 2; }; done; sleep 20; done
sleep 100; curl -s --max-time 3 http://127.0.0.1:8080/api/state | python3 -c "import json,sys;d=json.load(sys.stdin);print(d['ver'],d.get('region'))"
grep zentrale ~/Bodenstation/config.txt; df -h / | tail -1
