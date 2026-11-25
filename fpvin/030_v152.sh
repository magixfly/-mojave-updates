#timeout 120
level() { timeout 14 ffmpeg -hide_banner -nostats -rtsp_transport tcp -i rtsp://localhost:8554/mic -t 5 -af volumedetect -f null - 2>&1 | grep -E "mean_volume|max_volume|Audio:" | sed 's/.*\] //' | tr '\n' ' '; echo; }
echo "before: $(level)"
T=$(mktemp -d); curl -fsSL https://raw.githubusercontent.com/magixfly/-mojave-updates/carlin/fpv/fpv_pi_V1.5.2.tar.gz -o $T/p.tgz && tar -xzf $T/p.tgz -C $T
cp $T/pi/*.py $T/pi/usbcam.sh /opt/fpv/ && rm -rf /opt/fpv/cockpit && cp -r $T/pi/cockpit /opt/fpv/ && cp -r $T/pi/. /boot/firmware/pi/
C=/boot/firmware/fpv-config.txt
setkey() { if grep -qE "^$1[[:space:]]*=" $C; then sed -i -E "s|^$1[[:space:]]*=.*|$1 = $2|" $C; else echo "$1 = $2" >> $C; fi; }
setkey audio_bitrate_kbps 64; setkey audio_gain 4
python3 /opt/fpv/apply_config.py | grep sound; timeout 25 systemctl restart fpv-mediamtx; systemctl restart fpv-bridge; sleep 8
grep -m1 VERSION /opt/fpv/fpvcfg.py; amixer -c C960 2>/dev/null | grep -E "Front Left:" | head -1
journalctl -u fpv-mediamtx --since "-9s" --no-pager -o cat | grep -E "path mic|ERROR|WARNING|erroneous" | tail -3 | cut -c1-180
echo "after:  $(level)"
