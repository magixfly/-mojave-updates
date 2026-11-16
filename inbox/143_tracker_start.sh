# Tracker wieder starten (142 konnte systemd-run ohne XDG_RUNTIME_DIR nicht aufrufen)
export XDG_SESSION_TYPE=wayland DISPLAY=:0 WAYLAND_DISPLAY=wayland-0 XDG_RUNTIME_DIR=/run/user/$(id -u)
pgrep -f server.py >/dev/null && echo "server läuft schon" || systemd-run --user --collect --working-directory=$HOME/Bodenstation --setenv=XDG_SESSION_TYPE=wayland --setenv=DISPLAY=:0 --setenv=WAYLAND_DISPLAY=wayland-0 --setenv=XDG_RUNTIME_DIR=$XDG_RUNTIME_DIR bash ./start.sh
sleep 25
curl -s localhost:8080/api/state | python3 -c "import json,sys;d=json.load(sys.stdin);print('ver',d.get('ver'),'age',d.get('age'),'esp',d.get('esp'),'core via',(d.get('core') or {}).get('via'))"
pgrep -fc chromium
