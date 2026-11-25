#timeout 120
T=$(mktemp -d); curl -fsSL https://raw.githubusercontent.com/magixfly/-mojave-updates/carlin/fpv/fpv_pi_V1.4.7.tar.gz -o $T/p.tgz && tar -xzf $T/p.tgz -C $T
cp $T/pi/*.py $T/pi/usbcam.sh /opt/fpv/ && rm -rf /opt/fpv/cockpit && cp -r $T/pi/cockpit /opt/fpv/ && cp -r $T/pi/. /boot/firmware/pi/
grep -m1 VERSION /opt/fpv/fpvcfg.py; grep -E "^audio_" /boot/firmware/fpv-config.txt
python3 /opt/fpv/apply_config.py | tail -3; timeout 25 systemctl restart fpv-mediamtx; systemctl restart fpv-bridge; sleep 9
grep -nE "^  [a-z0-9]+:" /etc/fpv/mediamtx.yml
journalctl -u fpv-mediamtx --since "-10s" --no-pager -o cat | grep -E "path mic|mic\]|ERROR|WARNING|erroneous" | tail -5 | cut -c1-190
a=$(timeout 12 ffprobe -v error -rtsp_transport tcp -count_packets -select_streams a:0 -show_entries stream=codec_name,nb_read_packets -of csv=p=0 -read_intervals "%+4" rtsp://localhost:8554/mic 2>&1 | tail -1); echo "sound path: $a (opus, about 200 packets in 4 s expected)"
v=$(timeout 14 ffprobe -v error -rtsp_transport tcp -count_packets -select_streams v:0 -show_entries stream=nb_read_packets -of csv=p=0 -read_intervals "%+4" rtsp://localhost:8554/cam2 2>&1 | tail -1); echo "USB camera at the same time: $v pictures in 4 s (120 expected)"
