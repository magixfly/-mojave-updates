sleep 120
for i in $(seq 1 6); do curl -s -X POST -H "Content-Type: application/json" -d "{\"check\":1}" http://127.0.0.1:8080/api/update >/dev/null; sleep 10; curl -s -X POST -H "Content-Type: application/json" -d "{\"install\":1}" http://127.0.0.1:8080/api/update >/dev/null; for k in $(seq 1 20); do sleep 3; curl -s --max-time 2 http://127.0.0.1:8080/api/state | head -c 30 | grep -q '"2.81"' && { echo "2.81 läuft"; break 2; }; done; sleep 20; done
sleep 20
#screenshot
export XDG_RUNTIME_DIR=/run/user/$(id -u); sleep 20; WAYLAND_DISPLAY=wayland-0 grim outbox/223_pi.png 2>&1 || WAYLAND_DISPLAY=wayland-1 grim outbox/223_pi.png
which wtype ydotool 2>&1 | head -2
