#nobox
export XDG_RUNTIME_DIR=/run/user/$(id -u)
pkill -f "chromium.*--kiosk"; sleep 2; systemd-run --user --collect -p KillMode=process --setenv=WAYLAND_DISPLAY=wayland-0 --setenv=XDG_RUNTIME_DIR=$XDG_RUNTIME_DIR bash -c 'cd /home/user1/Bodenstation && exec bash ./kiosk.sh http://localhost:8080/'
sleep 25; WAYLAND_DISPLAY=wayland-0 grim outbox/329_pi.png
