#nobox
export XDG_RUNTIME_DIR=/run/user/$(id -u); WAYLAND_DISPLAY=wayland-0 grim outbox/334_pi.png
top -b -n 2 -d 3 -o %CPU | awk '/^top -/{n++} n==2' | sed -n '3p;8,11p' | cut -c1-120
