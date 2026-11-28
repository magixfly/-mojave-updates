#timeout 90
echo "mediamtx: $(/usr/local/bin/mediamtx --version 2>/dev/null || ls /opt/fpv /usr/local/bin | grep -i mtx)"
M=$(command -v mediamtx || ls /usr/local/bin/mediamtx /opt/fpv/mediamtx* 2>/dev/null | head -1); echo "binary: $M"; $M --version 2>&1 | head -2
echo "=== current rpiCamera config ==="; grep -h "rpiCamera" /etc/fpv/mediamtx.yml /opt/fpv/mediamtx.yml /usr/local/etc/mediamtx.yml 2>/dev/null | sort -u | head -30
echo "=== rpiCamera options the binary knows ==="; strings $M 2>/dev/null | grep -oE "^rpiCamera[A-Za-z0-9]+" | sort -u | tr '\n' ' '; echo
echo "=== sensor modes ==="; timeout 15 rpicam-hello --list-cameras 2>&1 | head -30 || timeout 15 libcamera-hello --list-cameras 2>&1 | head -30
echo "=== H.264 encoder controls (video11) ==="; v4l2-ctl -d /dev/video11 -l 2>&1 | head -40
echo "=== kernel / firmware ==="; uname -r; vcgencmd version 2>/dev/null | head -2
echo "[100%] done"
