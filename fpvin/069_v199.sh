#timeout 300
T=$(mktemp -d); curl -fsSL https://raw.githubusercontent.com/magixfly/-mojave-updates/carlin/fpv/fpv_pi_V1.9.9.tar.gz -o $T/p.tgz && tar -xzf $T/p.tgz -C $T 2>/dev/null
cp $T/pi/*.py $T/pi/usbcam.sh /opt/fpv/ && rm -rf /opt/fpv/cockpit && cp -r $T/pi/cockpit /opt/fpv/ && cp -r $T/pi/. /boot/firmware/pi/
C=/boot/firmware/fpv-config.txt; cp $C /boot/firmware/fpv-config.before-720p60.txt
sed -i -E 's/^video_width[[:space:]]*=[[:space:]]*[0-9]+/video_width        = 1280/; s/^video_height[[:space:]]*=[[:space:]]*[0-9]+/video_height       = 720/; s/^video_fps[[:space:]]*=[[:space:]]*[0-9]+/video_fps          = 60/; s/^video_idr_period[[:space:]]*=[[:space:]]*[0-9]+/video_idr_period   = 60/' $C
grep -E "^video_(width|height|fps|idr|bitrate)" $C | tr -s ' ' | tr '\n' ';'; echo
python3 /opt/fpv/apply_config.py >/dev/null; systemctl restart fpv-bridge; sleep 12
grep -m1 VERSION /opt/fpv/fpvcfg.py; systemctl is-active fpv-bridge fpv-mediamtx
grep -E "rpiCamera(Width|Height|FPS|Bitrate|IDRPeriod)" /etc/fpv/mediamtx.yml | head -5 | tr -s ' ' | tr '\n' ';'; echo
timeout 20 ffmpeg -hide_banner -nostats -rtsp_transport tcp -i rtsp://localhost:8554/cam -t 10 -c copy -f null - 2>&1 | grep -oE "[0-9]{3,4}x[0-9]{3,4}|frame= *[0-9]+|video:[0-9]+KiB|[0-9.]+ fps" | tr '\n' ' '; echo "(10 s)"
echo "encoder errors in the last 10 s: $(journalctl -u fpv-mediamtx --since "-10s" --no-pager -o cat | grep -c "QBUF")"
top -bn1 | sed -n 3p | cut -c1-70; top -bn1 -o %CPU | sed -n 8,11p | awk '{print $9, $12}' | tr '\n' ';'; echo; vcgencmd measure_temp
echo "[100%] done"
