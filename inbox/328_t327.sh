#nobox
for i in $(seq 1 6); do curl -s -X POST -H "Content-Type: application/json" -d "{\"check\":1}" http://127.0.0.1:8080/api/update >/dev/null; sleep 10; curl -s -X POST -H "Content-Type: application/json" -d "{\"install\":1}" http://127.0.0.1:8080/api/update >/dev/null; for k in $(seq 1 20); do sleep 3; curl -s --max-time 2 http://127.0.0.1:8080/api/state | head -c 30 | grep -q "\"3.27\"" && { echo "3.27 läuft"; break 2; }; done; sleep 20; done
curl -s -X POST localhost:8080/api/set -H 'Content-Type: application/json' -d '{"theme":"hud","map3d":0}'; echo
curl -s -X POST localhost:8080/api/sender -H 'Content-Type: application/json' -d '{"mac":"46:E8:8D:5C:B4:65","slot":1,"type":"car","sym":1,"col":"1a8cff","name":"MOJAVE"}'; echo
grep -E "^(theme|map3d|senders|icons|names)=" /home/user1/Bodenstation/config.txt | cut -c1-160
