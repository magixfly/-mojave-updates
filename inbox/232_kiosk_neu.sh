export XDG_RUNTIME_DIR=/run/user/$(id -u)
pkill -f "chromium.*--kiosk"; sleep 3
systemd-run --user --collect -p KillMode=process --setenv=WAYLAND_DISPLAY=wayland-0 --setenv=XDG_RUNTIME_DIR=$XDG_RUNTIME_DIR bash -c 'cd /home/user1/Bodenstation && exec bash ./kiosk.sh http://localhost:8080/' 2>&1
sleep 25; pgrep -af "chromium.*--kiosk" | head -1 | cut -c1-120
WAYLAND_DISPLAY=wayland-0 grim outbox/232_pi.png
