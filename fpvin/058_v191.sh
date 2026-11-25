#timeout 300
T=$(mktemp -d); curl -fsSL https://raw.githubusercontent.com/magixfly/-mojave-updates/carlin/fpv/fpv_pi_V1.9.1.tar.gz -o $T/p.tgz && tar -xzf $T/p.tgz -C $T 2>/dev/null
cp $T/pi/*.py $T/pi/usbcam.sh /opt/fpv/ && rm -rf /opt/fpv/cockpit && cp -r $T/pi/cockpit /opt/fpv/ && cp -r $T/pi/. /boot/firmware/pi/
grep -q record_armed /boot/firmware/fpv-config.txt || sed -n '/^# Recording of the drive on the Pi/,$p' $T/pi/fpv-config.txt >> /boot/firmware/fpv-config.txt
systemctl restart fpv-bridge; sleep 7
grep -m1 VERSION /opt/fpv/fpvcfg.py; grep -c "exact start of each file" /opt/fpv/recorder.py; systemctl is-active fpv-bridge fpv-mediamtx
P() { curl -s -X POST -H "X-FPV: 1" -H "Content-Type: application/json" -d "$1" http://localhost:8080/api/rec >/dev/null; }
P '{"do":"start"}'; sleep 12; P '{"do":"stop"}'
D=$(ls -d /var/lib/fpv/rec/*/ | tail -1); python3 -c "
import json; m=json.load(open('$D/meta.json')); print('dur', m['dur'], [(g['path'], g['t0'], g['t1']) for g in m['segs']])"
for f in cam cam2 mic; do [ -f $D/$f.mp4 ] && echo "$f: $(ffprobe -v error -show_entries format=duration -of csv=p=0 $D/$f.mp4)"; done
curl -s -X POST -H "X-FPV: 1" -H "Content-Type: application/json" -d "{\"do\":\"delete\",\"id\":\"$(basename $D)\"}" http://localhost:8080/api/rec; echo
ls /var/lib/fpv/rec | wc -l
