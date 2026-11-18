#nobox
# Tracker-Pi: wer braucht die CPU? + FPV-Messwerte der Tracker-Seite
top -b -n 2 -d 3 -o %CPU | awk '/^top -/{n++} n==2' | sed -n '1,4p;7,16p' | cut -c1-110
vcgencmd measure_temp; vcgencmd get_throttled
echo "--- FPV-Messung Tracker (letzte Einträge)"; grep fpvstat /tmp/tracker_dbg.txt | tail -4 | cut -c1-260
export XDG_RUNTIME_DIR=/run/user/$(id -u); WAYLAND_DISPLAY=wayland-0 grim outbox/267_pi.png
