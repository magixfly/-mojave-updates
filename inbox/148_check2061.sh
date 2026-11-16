#screenshot
curl -s http://127.0.0.1:8080/api/update; echo
v=$(curl -s http://127.0.0.1:8080/api/state | head -c 40); echo "$v"
case "$v" in *2.0.61*) ;; *) curl -s -X POST -H "Content-Type: application/json" -d "{\"install\":1}" http://127.0.0.1:8080/api/update; for i in $(seq 1 30); do sleep 3; curl -s http://127.0.0.1:8080/api/state | head -c 30 | grep -q 2.0.61 && { echo "2.0.61 läuft"; break; }; done;; esac
sleep 25
