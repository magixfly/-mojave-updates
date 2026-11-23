#nobox
export XDG_RUNTIME_DIR=/run/user/$(id -u) WAYLAND_DISPLAY=wayland-0; grim -s 0.6 -t jpeg -q 60 /tmp/s.jpg && echo B64; base64 -w0 /tmp/s.jpg; echo
