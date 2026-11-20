#nobox
export XDG_RUNTIME_DIR=/run/user/$(id -u); WAYLAND_DISPLAY=wayland-0 grim outbox/349_pi.png
curl -s localhost:8080/api/state | python3 -c "import json,sys;d=json.load(sys.stdin);print(d.get(\"me\"),d.get(\"lat\"),d.get(\"vgps\"))"
