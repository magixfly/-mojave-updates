sleep 120
for i in $(seq 1 6); do curl -s -X POST -H "Content-Type: application/json" -d "{\"check\":1}" http://127.0.0.1:8080/api/update >/dev/null; sleep 10; curl -s -X POST -H "Content-Type: application/json" -d "{\"install\":1}" http://127.0.0.1:8080/api/update >/dev/null; for k in $(seq 1 20); do sleep 3; curl -s --max-time 2 http://127.0.0.1:8080/api/state | head -c 30 | grep -q '"2.78"' && { echo "2.78 läuft"; break 2; }; done; sleep 20; done
sleep 20
#screenshot
ip neigh | grep -i "dc:a6:32:09:df"
for ip in 192.168.178.159 192.168.178.175; do echo "$ip: $(curl -s -m 4 http://$ip/ | grep -io '<title>[^<]*' | head -1)"; done
adb shell cat /data/data/at.magixfly.coretracker/shared_prefs/ct.xml | grep -i cosmo
