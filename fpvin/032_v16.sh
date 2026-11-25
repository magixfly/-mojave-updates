#timeout 600
echo "[10%] installing the noise filter (gstreamer1.0-plugins-bad)"
DEBIAN_FRONTEND=noninteractive timeout 400 apt-get install -y -qq gstreamer1.0-plugins-bad >/dev/null 2>&1; echo "apt exit $?"
echo "[60%] installing V1.6"
T=$(mktemp -d); curl -fsSL https://raw.githubusercontent.com/magixfly/-mojave-updates/carlin/fpv/fpv_pi_V1.6.tar.gz -o $T/p.tgz && tar -xzf $T/p.tgz -C $T
cp $T/pi/*.py $T/pi/usbcam.sh /opt/fpv/ && rm -rf /opt/fpv/cockpit && cp -r $T/pi/cockpit /opt/fpv/ && cp -r $T/pi/. /boot/firmware/pi/
C=/boot/firmware/fpv-config.txt
setkey() { if grep -qE "^$1[[:space:]]*=" $C; then sed -i -E "s|^$1[[:space:]]*=.*|$1 = $2|" $C; else echo "$1 = $2" >> $C; fi; }
setkey audio_filter 3; setkey audio_gain 1; setkey audio_bitrate_kbps 64
python3 /opt/fpv/apply_config.py | grep sound; timeout 25 systemctl restart fpv-mediamtx; systemctl restart fpv-bridge; sleep 9
echo "[90%] checking"
grep -m1 VERSION /opt/fpv/fpvcfg.py; systemctl is-active fpv-bridge fpv-mediamtx
journalctl -u fpv-mediamtx --since "-10s" --no-pager -o cat | grep -E "path mic|ERROR|WARNING|erroneous" | tail -4 | cut -c1-190
timeout 14 ffmpeg -hide_banner -nostats -rtsp_transport tcp -i rtsp://localhost:8554/mic -t 5 -af volumedetect -f null - 2>&1 | grep -E "mean_volume|max_volume" | sed 's/.*\] //' | tr '\n' ' '; echo
curl -s http://localhost:8080/api/status | python3 -c "import sys,json;d=json.load(sys.stdin);print({k:d.get(k) for k in ('v','trip_m','home_set','home_dist_m','fc_ok')})"
echo "[100%] done"
