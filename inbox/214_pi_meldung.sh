free -m; echo; ps -eo rss,comm --sort=-rss | head -8
journalctl --user -n 30 --no-pager 2>/dev/null | grep -i "memory\|oom\|notif" | tail -8
dmesg 2>/dev/null | grep -i "oom\|killed" | tail -5
export XDG_RUNTIME_DIR=/run/user/$(id -u); WAYLAND_DISPLAY=wayland-0 grim outbox/214_pi.png 2>&1 || WAYLAND_DISPLAY=wayland-1 grim outbox/214_pi.png 2>&1; ls -la outbox/214_pi.png
