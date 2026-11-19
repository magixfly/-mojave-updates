#nobox
export XDG_RUNTIME_DIR=/run/user/$(id -u); WAYLAND_DISPLAY=wayland-0 grim outbox/331_pi.png
curl -s -m 3 -o /dev/null -w "cosmo %{http_code}\n" http://192.168.178.175/
grep -E "^(fpv_mode|map3d|theme)=" /home/user1/Bodenstation/config.txt | cut -c1-30
tail -5 /home/user1/Bodenstation/server.log | cut -c1-160
