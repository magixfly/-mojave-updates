#timeout 300
T=$(mktemp -d); curl -fsSL https://raw.githubusercontent.com/magixfly/-mojave-updates/carlin/fpv/fpv_pi_V1.8.5.tar.gz -o $T/p.tgz && tar -xzf $T/p.tgz -C $T
cp $T/pi/*.py $T/pi/usbcam.sh /opt/fpv/ && rm -rf /opt/fpv/cockpit && cp -r $T/pi/cockpit /opt/fpv/ && cp -r $T/pi/. /boot/firmware/pi/
grep -q cam2_pip_width /boot/firmware/fpv-config.txt || sed -n '/^# USB camera while it is only the small picture/,$p' $T/pi/fpv-config.txt >> /boot/firmware/fpv-config.txt
python3 /opt/fpv/apply_config.py | grep -i "usb\|small"; timeout 25 systemctl restart fpv-mediamtx; systemctl restart fpv-bridge; sleep 8
grep -m1 VERSION /opt/fpv/fpvcfg.py; systemctl is-active fpv-bridge fpv-mediamtx; curl -s http://localhost:8080/api/paths; echo
DEV=$(grep -m1 -o "usbcam.sh /dev/[a-z0-9/_.:-]*" /etc/fpv/mediamtx.yml | cut -d' ' -f2); echo "device $DEV"
v4l2-ctl -d $DEV --list-formats-ext 2>/dev/null | awk '/MJPG/{m=1} /YUYV/{m=0} m && /Size|Interval/' | tr -s ' \t' ' ' | grep -A3 "640x360\|1280x720" | tr '\n' ' ' | cut -c1-400; echo
rd() { timeout 20 ffmpeg -hide_banner -nostats -rtsp_transport tcp -i rtsp://localhost:8554/$1 -t 5 -c copy -f null - 2>&1 | grep -oE "[0-9]{3,4}x[0-9]{3,4}|frame= *[0-9]+|video:[0-9]+KiB" | tr '\n' ' '; }
S=$(date +%s%N); echo "cam2s: $(rd cam2s) ($(( ($(date +%s%N) - S) / 1000000 )) ms incl. 5 s reading)"
S=$(date +%s%N); echo "then cam2: $(rd cam2) ($(( ($(date +%s%N) - S) / 1000000 )) ms incl. 5 s reading)"
S=$(date +%s%N); echo "then cam2s again: $(rd cam2s) ($(( ($(date +%s%N) - S) / 1000000 )) ms incl. 5 s reading)"
ls /run/fpv-usbcam-* 2>/dev/null; journalctl -u fpv-mediamtx --since "-40s" --no-pager -o cat | grep "usbcam\]" | tail -8 | cut -c1-150
echo "[100%] done"
