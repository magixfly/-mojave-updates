#nobox
export XDG_RUNTIME_DIR=/run/user/$(id -u) WAYLAND_DISPLAY=wayland-0; grim -s 0.5 -l 9 /tmp/s.png && echo B64; base64 -w0 /tmp/s.png; echo
