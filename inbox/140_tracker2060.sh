# Tracker auf 2.0.60 aktualisieren (GitHub-Cache bis ~5 min)
for i in $(seq 1 14); do
  curl -s -X POST -H 'Content-Type: application/json' -d '{"check":1}' http://127.0.0.1:8080/api/update >/dev/null; sleep 8
  v=$(curl -s http://127.0.0.1:8080/api/update); case "$v" in *2.0.60*) echo "online: 2.0.60"; break;; esac; sleep 20
done
curl -s -X POST -H 'Content-Type: application/json' -d '{"install":1}' http://127.0.0.1:8080/api/update >/dev/null
for i in $(seq 1 30); do sleep 3; v=$(curl -s http://127.0.0.1:8080/api/update 2>/dev/null); case "$v" in *'"cur": "2.0.60"'*) echo "Tracker 2.0.60 läuft"; break;; esac; done
sleep 20
sleep 5
curl -s -X POST localhost:8080/api/devices >/dev/null 2>&1; curl -s "localhost:8080/api/devices?scan=1" >/dev/null 2>&1; sleep 25
curl -s localhost:8080/api/devices | python3 -c "import json,sys;d=json.load(sys.stdin).get('d',{});print('navi',d.get('navi'));print('core',d.get('core'))"
