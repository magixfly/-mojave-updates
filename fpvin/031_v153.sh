#timeout 120
T=$(mktemp -d); curl -fsSL https://raw.githubusercontent.com/magixfly/-mojave-updates/carlin/fpv/fpv_pi_V1.5.3.tar.gz -o $T/p.tgz && tar -xzf $T/p.tgz -C $T
cp $T/pi/*.py $T/pi/usbcam.sh /opt/fpv/ && rm -rf /opt/fpv/cockpit && cp -r $T/pi/cockpit /opt/fpv/ && cp -r $T/pi/. /boot/firmware/pi/
systemctl restart fpv-bridge; sleep 2; grep -m1 VERSION /opt/fpv/fpvcfg.py; systemctl is-active fpv-bridge fpv-mediamtx
count() { timeout 14 ffprobe -v error -rtsp_transport tcp -count_packets -select_streams $3 -show_entries stream=nb_read_packets -of csv=p=0 -read_intervals "%+$2" rtsp://localhost:8554/$1 2>&1 | tail -1; }
count cam 5 v:0 > /tmp/a1 & count cam2 5 v:0 > /tmp/a2 & count mic 5 a:0 > /tmp/a3 & sleep 4; cpu=$(top -b -n1 -w 200 | grep -E "gst-launch|ffmpeg|mtxrpicam|mediamtx" | awk '{s+=$9} END {print s+0}'); wait
echo "all at once for 5 s: main camera $(cat /tmp/a1) (150 expected), USB camera $(cat /tmp/a2) (150), sound $(cat /tmp/a3) (250)   cpu of video programs ${cpu}%"
vcgencmd measure_temp; vcgencmd get_throttled
