#timeout 200
C=/boot/firmware/fpv-config.txt; sed -i -E 's/^cam2_pip_fps[[:space:]]*=.*/cam2_pip_fps          = 30/' $C
rm -f /run/fpv-usbcam-*; python3 /opt/fpv/apply_config.py | grep -i small; sleep 4
DEV=$(ls /dev/v4l/by-id/*EMEET*index0 | head -1)
v4l2-ctl -d $DEV --list-formats-ext 2>/dev/null | grep -A40 MJPG | grep -E "Size|Interval" | tr -s ' \t' ' ' | head -24 | tr '\n' ';' | cut -c1-700; echo
rd() { timeout 22 ffmpeg -hide_banner -nostats -rtsp_transport tcp -i rtsp://localhost:8554/$1 -t 5 -c copy -f null - 2>&1 | grep -oE "[0-9]{3,4}x[0-9]{3,4}|frame= *[0-9]+|video:[0-9]+KiB" | tr '\n' ' '; }
for p in cam2s cam2 cam2s cam2; do S=$(date +%s%N); echo "$p: $(rd $p) ($(( ($(date +%s%N) - S) / 1000000 )) ms incl. 5 s reading)"; done
ls /run/fpv-usbcam-* 2>/dev/null; journalctl -u fpv-mediamtx --since "-45s" --no-pager -o cat | grep -i "usbcam\]\|not-negotiated\|error" | tail -10 | cut -c1-170
top -bn1 | head -4 | tail -2 | cut -c1-90
