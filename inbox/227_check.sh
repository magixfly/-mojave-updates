curl -s -m 4 http://127.0.0.1:8080/api/state | head -c 80; echo
pgrep -af "server.py" | head -3
tail -20 ~/mojave/bodenstation/server.log 2>/dev/null; ls ~ | head -20
journalctl --user -n 20 --no-pager 2>/dev/null | tail -10
export XDG_RUNTIME_DIR=/run/user/$(id -u); WAYLAND_DISPLAY=wayland-0 grim outbox/227_pi.png 2>&1 || WAYLAND_DISPLAY=wayland-1 grim outbox/227_pi.png
