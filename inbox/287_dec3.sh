#nobox
sleep 50; grep fpvstat /tmp/tracker_dbg.txt | tail -1 | cut -c1-300
top -b -n 2 -d 4 -o %CPU | awk "/^top -/{n++} n==2" | sed -n "3p;8,11p" | cut -c1-100
vcgencmd measure_temp
export XDG_RUNTIME_DIR=/run/user/$(id -u); WAYLAND_DISPLAY=wayland-0 grim outbox/287_pi.png
