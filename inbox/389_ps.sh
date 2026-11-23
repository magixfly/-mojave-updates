#nobox
ps aux | grep -iE "chrom|kiosk|firefox|cage|labwc|wayfire" | grep -v grep | cut -c1-250 | head -8
echo XDG=$(ls /run/user/*/ 2>/dev/null | grep wayland)
export XDG_RUNTIME_DIR=/run/user/$(id -u); export WAYLAND_DISPLAY=$(ls $XDG_RUNTIME_DIR | grep -m1 "^wayland-[0-9]$"); grim /tmp/s.png && cd ~ && base64 -w0 /tmp/s.png > /tmp/s.b64 && wc -c /tmp/s.b64
