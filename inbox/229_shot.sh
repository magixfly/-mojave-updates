sleep 10; export XDG_RUNTIME_DIR=/run/user/$(id -u); WAYLAND_DISPLAY=wayland-0 grim outbox/229_pi.png 2>&1 || WAYLAND_DISPLAY=wayland-1 grim outbox/229_pi.png
