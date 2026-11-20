#nobox
curl -s localhost:8080/api/state | python3 -c "
import json,sys;d=json.load(sys.stdin)
print({k:d.get(k) for k in [\"ver\",\"lat\",\"lon\",\"sats\",\"age\",\"vgps\",\"src\",\"esp\",\"warn\",\"slot\",\"name\",\"me\",\"hw\"]})"
export XDG_RUNTIME_DIR=/run/user/$(id -u); WAYLAND_DISPLAY=wayland-0 grim outbox/352_pi.png
