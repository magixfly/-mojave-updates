#screenshot
#nobox
# Tracker auf 2.0.47 aktualisieren (GitHub-Cache bis ~5 min)
for i in $(seq 1 14); do
  curl -s -X POST -H 'Content-Type: application/json' -d '{"check":1}' http://127.0.0.1:8080/api/update >/dev/null; sleep 8
  v=$(curl -s http://127.0.0.1:8080/api/update); case "$v" in *2.0.47*) echo "online: 2.0.47"; break;; esac; sleep 20
done
curl -s -X POST -H 'Content-Type: application/json' -d '{"install":1}' http://127.0.0.1:8080/api/update >/dev/null
for i in $(seq 1 30); do sleep 3; v=$(curl -s http://127.0.0.1:8080/api/update 2>/dev/null); case "$v" in *'"cur": "2.0.47"'*) echo "Tracker 2.0.47 läuft"; break;; esac; done
sleep 20
