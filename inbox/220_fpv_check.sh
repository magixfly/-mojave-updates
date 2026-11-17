curl -s -m 5 http://127.0.0.1:8080/api/devices | python3 -c "import sys,json;d=json.load(sys.stdin).get('d',{});print('cosmo:',d.get('cosmo'))"
export XDG_RUNTIME_DIR=/run/user/$(id -u); WAYLAND_DISPLAY=wayland-0 grim outbox/220_pi.png 2>&1 || WAYLAND_DISPLAY=wayland-1 grim outbox/220_pi.png
