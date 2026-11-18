#nobox
for i in $(seq 1 6); do curl -s -X POST -H "Content-Type: application/json" -d "{\"check\":1}" http://127.0.0.1:8080/api/update >/dev/null; sleep 10; curl -s -X POST -H "Content-Type: application/json" -d "{\"install\":1}" http://127.0.0.1:8080/api/update >/dev/null; for k in $(seq 1 20); do sleep 3; curl -s --max-time 2 http://127.0.0.1:8080/api/state | head -c 30 | grep -q "\"3.24\"" && { echo "3.24 läuft"; break 2; }; done; sleep 20; done
grep -E "^(theme|map3d|night|fpv_mode|pip_pos)=" /home/user1/Bodenstation/config.txt | cut -c1-50
export XDG_RUNTIME_DIR=/run/user/$(id -u)
pkill -f "chromium.*--kiosk"; sleep 2; systemd-run --user --collect -p KillMode=process --setenv=WAYLAND_DISPLAY=wayland-0 --setenv=XDG_RUNTIME_DIR=$XDG_RUNTIME_DIR bash -c 'cd /home/user1/Bodenstation && exec bash ./kiosk.sh http://localhost:8080/'
sleep 25; WAYLAND_DISPLAY=wayland-0 grim outbox/324_pi.png
