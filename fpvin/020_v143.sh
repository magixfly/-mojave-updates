#timeout 420
T=$(mktemp -d); curl -fsSL https://raw.githubusercontent.com/magixfly/-mojave-updates/carlin/fpv/fpv_pi_V1.4.3.tar.gz -o $T/p.tgz && tar -xzf $T/p.tgz -C $T
cp $T/pi/*.py $T/pi/usbcam.sh /opt/fpv/ && rm -rf /opt/fpv/cockpit && cp -r $T/pi/cockpit /opt/fpv/ && mkdir -p /boot/firmware/pi && cp -r $T/pi/. /boot/firmware/pi/
grep -m1 VERSION /opt/fpv/fpvcfg.py; systemctl restart fpv-bridge
C=/boot/firmware/fpv-config.txt; DM0=$(dmesg | wc -l); rm -f /run/fpv-usbcam-*
setkey() { if grep -qE "^$1[[:space:]]*=" $C; then sed -i -E "s|^$1[[:space:]]*=.*|$1 = $2|" $C; else echo "$1 = $2" >> $C; fi; }
count() { timeout 16 ffprobe -v error -rtsp_transport tcp -count_packets -select_streams v:0 -show_entries stream=nb_read_packets -of csv=p=0 -read_intervals "%+$2" rtsp://localhost:8554/$1 2>&1 | tail -1; }
try() { setkey cam2_width $1; setkey cam2_height $2; setkey cam2_bitrate_kbps $3; setkey cam2_pipeline auto; setkey cam2_enable 1
  python3 /opt/fpv/apply_config.py >/dev/null 2>&1; timeout 25 systemctl restart fpv-mediamtx; sleep 6
  echo; echo "##### USB camera $1x$2 through the video server, main camera running"
  count cam2 8 > /tmp/c2.txt & sleep 7; cpu=$(top -b -n1 -w 200 | grep -E "gst-launch|ffmpeg" | awk '{s+=$9} END {print s+0}'); mc=$(count cam 4); wait
  echo "USB camera: $(cat /tmp/c2.txt) pictures in 8 s (240 expected), cpu ${cpu}%   main camera: ${mc} in 4 s (120 expected)"
  journalctl -u fpv-mediamtx --since "-22s" --no-pager -o cat | grep -E "usbcam|erroneous|ERROR|WARNING" | tail -4 | cut -c1-200
  echo "kernel errors so far: $(dmesg | tail -n +$((DM0+1)) | grep -ciE 'timed out waiting|failed to create component')"; ls /run/fpv-usbcam-* 2>/dev/null; sleep 12; }
try 1280 720 1500; R720=$(cat /tmp/c2.txt)
try 1920 1080 3000; R1080=$(cat /tmp/c2.txt)
echo; if [ "${R1080:-0}" -ge 200 ] 2>/dev/null; then echo "RESULT: keeping 1920x1080"; else echo "RESULT: 1080p not good enough ($R1080) - back to 1280x720"; setkey cam2_width 1280; setkey cam2_height 720; setkey cam2_bitrate_kbps 1500; python3 /opt/fpv/apply_config.py >/dev/null 2>&1; timeout 25 systemctl restart fpv-mediamtx; fi
sleep 3; grep -E "^cam2_(width|height|bitrate|pipeline)" $C; pgrep -a "gst|ffmpeg" | cut -c1-70; vcgencmd measure_temp; vcgencmd get_throttled
