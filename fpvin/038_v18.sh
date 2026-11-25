#timeout 300
echo "[30%] installing V1.8"
T=$(mktemp -d); curl -fsSL https://raw.githubusercontent.com/magixfly/-mojave-updates/carlin/fpv/fpv_pi_V1.8.tar.gz -o $T/p.tgz && tar -xzf $T/p.tgz -C $T
cp $T/pi/*.py $T/pi/usbcam.sh /opt/fpv/ && rm -rf /opt/fpv/cockpit && cp -r $T/pi/cockpit /opt/fpv/ && cp -r $T/pi/. /boot/firmware/pi/
grep -q emergency_width /boot/firmware/fpv-config.txt || sed -n '/^# Emergency picture/,$p' $T/pi/fpv-config.txt >> /boot/firmware/fpv-config.txt
systemctl restart fpv-bridge; sleep 6
echo "[70%] checking"
grep -m1 VERSION /opt/fpv/fpvcfg.py; systemctl is-active fpv-bridge fpv-mediamtx
curl -s http://localhost:8080/ | grep -c "rdial\|setEmergency"
probe() { timeout 6 ffprobe -v error -rtsp_transport tcp -select_streams v:0 -show_entries stream=width,height -of csv=p=0 rtsp://localhost:8554/cam 2>/dev/null | head -1; }
P() { curl -s -X POST -H "X-FPV: 1" -H "Content-Type: application/json" -d "$1" http://localhost:8080/api/emergency; echo; }
echo "normal: $(probe)"
S=$(date +%s%N); P '{"on":true}'; for i in $(seq 1 30); do R=$(probe); [ "$R" = "640,360" ] && break; sleep 0.2; done; echo "emergency: $R after $(( ($(date +%s%N) - S) / 1000000 )) ms"
curl -s http://localhost:8080/api/emergency; echo
timeout 9 ffmpeg -hide_banner -nostats -rtsp_transport tcp -i rtsp://localhost:8554/cam -t 5 -c copy -f null - 2>&1 | grep -oE "frame= *[0-9]+|video:[0-9]+KiB" | tr '\n' ' '; echo
S=$(date +%s%N); P '{"on":false}'; for i in $(seq 1 30); do R=$(probe); [ "$R" = "1920,1080" ] && break; sleep 0.2; done; echo "back: $R after $(( ($(date +%s%N) - S) / 1000000 )) ms"
echo "[100%] done"
