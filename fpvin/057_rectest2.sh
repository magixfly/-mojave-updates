#timeout 300
T=$(mktemp -d); curl -fsSL https://raw.githubusercontent.com/magixfly/-mojave-updates/carlin/fpv/fpv_pi_V1.9.tar.gz -o $T/p.tgz && tar -xzf $T/p.tgz -C $T 2>/dev/null
cp $T/pi/recorder.py /opt/fpv/ && cp $T/pi/recorder.py /boot/firmware/pi/; systemctl restart fpv-bridge; sleep 7
P() { curl -s -X POST -H "X-FPV: 1" -H "Content-Type: application/json" -d "$1" http://localhost:8080/api/rec >/dev/null; }
P '{"do":"start"}'; sleep 12; P '{"do":"stop"}'
D=$(ls -d /var/lib/fpv/rec/*/ | tail -1); python3 -c "
import json; m=json.load(open('$D/meta.json')); print('dur', m['dur'], [(g['path'], g['t0'], g['size']) for g in m['segs']])"
for f in cam cam2 mic; do [ -f $D/$f.mp4 ] && echo "$f: $(ffprobe -v error -show_entries stream=codec_name,width,height -show_entries format=duration -of csv=p=0 $D/$f.mp4 | tr '\n' ' ')"; done
curl -s -X POST -H "X-FPV: 1" -H "Content-Type: application/json" -d "{\"do\":\"delete\",\"id\":\"$(basename $D)\"}" http://localhost:8080/api/rec; echo
