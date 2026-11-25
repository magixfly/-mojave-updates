#timeout 120
T=$(mktemp -d); curl -fsSL https://raw.githubusercontent.com/magixfly/-mojave-updates/carlin/fpv/fpv_pi_V1.4.4.tar.gz -o $T/p.tgz && tar -xzf $T/p.tgz -C $T
cp $T/pi/*.py $T/pi/usbcam.sh /opt/fpv/ && rm -rf /opt/fpv/cockpit && cp -r $T/pi/cockpit /opt/fpv/ && cp -r $T/pi/. /boot/firmware/pi/
C=/boot/firmware/fpv-config.txt
sed -i -E "s|^cam2_width[[:space:]]*=.*|cam2_width = 1280|; s|^cam2_height[[:space:]]*=.*|cam2_height = 720|; s|^cam2_bitrate_kbps[[:space:]]*=.*|cam2_bitrate_kbps = 1500|" $C
rm -f /run/fpv-usbcam-*; python3 /opt/fpv/apply_config.py; timeout 25 systemctl restart fpv-mediamtx; systemctl restart fpv-bridge; sleep 6
grep -m1 VERSION /opt/fpv/fpvcfg.py; grep -nE "^  [a-z0-9]+:|usbcam" /etc/fpv/mediamtx.yml | cut -c1-150
n=$(timeout 14 ffprobe -v error -rtsp_transport tcp -count_packets -select_streams v:0 -show_entries stream=nb_read_packets -of csv=p=0 -read_intervals "%+6" rtsp://localhost:8554/cam2 2>&1 | tail -1)
echo "USB camera: $n pictures in 6 s (180 expected)"; journalctl -u fpv-mediamtx --since "-12s" --no-pager -o cat | grep usbcam | tail -1 | cut -c1-160
systemctl is-active fpv-bridge fpv-mediamtx; vcgencmd measure_temp
