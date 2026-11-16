#screenshot
sleep 200
for i in $(seq 1 10); do curl -s -X POST -H "Content-Type: application/json" -d "{\"install\":1}" http://127.0.0.1:8080/api/update >/dev/null; for k in $(seq 1 20); do sleep 3; curl -s --max-time 2 http://127.0.0.1:8080/api/state | head -c 30 | grep -q 2.0.61 && { echo "2.0.61 läuft"; break 2; }; done; curl -s http://127.0.0.1:8080/api/update | head -c 120; echo; sleep 30; done
sleep 25
