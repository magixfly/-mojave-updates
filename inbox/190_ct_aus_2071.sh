#screenshot
nmcli con mod CoreTracker connection.autoconnect no && echo "CoreTracker autoconnect aus"
nmcli con mod "Optimus Prime" connection.autoconnect-priority 50 && echo "Optimus Prime Prioritaet 50"
nmcli -t -f NAME,AUTOCONNECT,AUTOCONNECT-PRIORITY con show
for i in $(seq 1 6); do curl -s -X POST -H "Content-Type: application/json" -d "{\"check\":1}" http://127.0.0.1:8080/api/update >/dev/null; sleep 10; curl -s -X POST -H "Content-Type: application/json" -d "{\"install\":1}" http://127.0.0.1:8080/api/update >/dev/null; for k in $(seq 1 20); do sleep 3; curl -s --max-time 2 http://127.0.0.1:8080/api/state | head -c 30 | grep -q '"2.71"' && { echo "2.71 läuft"; break 2; }; done; curl -s http://127.0.0.1:8080/api/update | head -c 100; echo; sleep 20; done
sleep 20
