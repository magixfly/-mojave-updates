for i in $(seq 1 6); do curl -s -X POST -H "Content-Type: application/json" -d '{"check":1}' http://127.0.0.1:8080/api/update >/dev/null; sleep 10; curl -s -X POST -H "Content-Type: application/json" -d '{"install":1}' http://127.0.0.1:8080/api/update >/dev/null; for k in $(seq 1 20); do sleep 3; curl -s --max-time 2 http://127.0.0.1:8080/api/state | head -c 30 | grep -q '"3.08"' && { echo "3.08 läuft"; break 2; }; done; sleep 20; done
export XDG_RUNTIME_DIR=/run/user/$(id -u)
sleep 40; top -b -n 2 -d 2 -o %CPU | awk '/^top -/{n++} n==2' | sed -n 3p
WAYLAND_DISPLAY=wayland-0 grim outbox/262_pi.png
#screenshot
