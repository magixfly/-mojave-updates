#nobox
# Kiosk-Chromium: Hardware-Videodecoder einschalten (Sicherung kiosk.sh.v309), Kiosk neu starten
cd ~/Bodenstation
[ -f kiosk.sh.v309 ] || cp kiosk.sh kiosk.sh.v309
grep -q "AcceleratedVideoDecodeLinuxGL" kiosk.sh || sed -i 's#--autoplay-policy=no-user-gesture-required#--autoplay-policy=no-user-gesture-required --enable-features=AcceleratedVideoDecodeLinuxGL,AcceleratedVideoDecodeLinuxZeroCopyGL,WebRtcHWDecoding --ignore-gpu-blocklist --enable-accelerated-video-decode#' kiosk.sh
grep -o "enable-features=[^ ]*" kiosk.sh
export XDG_RUNTIME_DIR=/run/user/$(id -u)
pkill -f "chromium.*--kiosk"; sleep 3
systemd-run --user --collect -p KillMode=process bash -c "cd ~/Bodenstation && exec bash ./kiosk.sh > /tmp/kiosk.log 2>&1"
sleep 15; pgrep -fc "chromium" ; tail -2 /tmp/kiosk.log
WAYLAND_DISPLAY=wayland-0 grim outbox/286_pi.png
