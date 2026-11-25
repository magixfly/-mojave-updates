#timeout 300
T=$(mktemp -d); curl -fsSL https://raw.githubusercontent.com/magixfly/-mojave-updates/carlin/fpv/fpv_pi_V1.9.tar.gz -o $T/p.tgz && tar -xzf $T/p.tgz -C $T 2>/dev/null
cp $T/pi/*.py $T/pi/usbcam.sh /opt/fpv/ && rm -rf /opt/fpv/cockpit && cp -r $T/pi/cockpit /opt/fpv/ && cp -r $T/pi/. /boot/firmware/pi/
grep -q record_armed /boot/firmware/fpv-config.txt || sed -n '/^# Recording of the drive on the Pi/,$p' $T/pi/fpv-config.txt >> /boot/firmware/fpv-config.txt
mkdir -p /var/lib/fpv/rec; systemctl restart fpv-bridge; sleep 7
grep -m1 VERSION /opt/fpv/fpvcfg.py; systemctl is-active fpv-bridge fpv-mediamtx; df -h /var/lib/fpv | tail -1
P() { curl -s -X POST -H "X-FPV: 1" -H "Content-Type: application/json" -d "$1" http://localhost:8080/api/rec; echo; }
echo "[50%] test recording 12 s"
P '{"do":"start"}'; sleep 6; top -bn1 | sed -n 3p | cut -c1-80; pgrep -af "ffmpeg.*rec/" | awk '{print $1}' | while read p; do ps -o %cpu=,comm= -p $p; done | tr '\n' ';'; echo; sleep 6; P '{"do":"stop"}'
D=$(ls -d /var/lib/fpv/rec/*/ | tail -1); ls -la $D | tail -5; cat $D/meta.json | cut -c1-500; echo
for f in cam cam2 mic; do [ -f $D/$f.mp4 ] && echo "$f: $(ffprobe -v error -show_entries stream=codec_name,width,height -show_entries format=duration -of csv=p=0 $D/$f.mp4 | tr '\n' ' ')"; done
journalctl -u fpv-bridge --since "-25s" --no-pager -o cat | grep "\[rec\]" | tail -4
curl -s -X POST -H "X-FPV: 1" -H "Content-Type: application/json" -d "{\"do\":\"delete\",\"id\":\"$(basename $D)\"}" http://localhost:8080/api/rec; echo
echo "[100%] done"
