#timeout 200
T=$(mktemp -d); curl -fsSL https://raw.githubusercontent.com/magixfly/-mojave-updates/carlin/fpv/fpv_pi_V1.9.3.tar.gz -o $T/p.tgz && tar -xzf $T/p.tgz -C $T 2>/dev/null
cp $T/pi/*.py $T/pi/usbcam.sh /opt/fpv/ && rm -rf /opt/fpv/cockpit && cp -r $T/pi/cockpit /opt/fpv/ && cp -r $T/pi/. /boot/firmware/pi/
N0=$(ls /var/lib/fpv/rec | wc -l); curl -s http://localhost:8080/api/rec | python3 -c "import sys,json; d=json.load(sys.stdin); print('recording running before the update:', d['on'])"
systemctl restart fpv-bridge; sleep 7
grep -m1 VERSION /opt/fpv/fpvcfg.py; systemctl is-active fpv-bridge fpv-mediamtx
P() { curl -s -X POST -H "X-FPV: 1" -H "Content-Type: application/json" -d "$1" http://localhost:8080/api/rec >/dev/null; }
P '{"do":"start"}'; sleep 10; P '{"do":"stop"}'; sleep 1
D=$(ls -d /var/lib/fpv/rec/*/ | tail -1); python3 -c "
import json; m=json.load(open('$D/meta.json')); print('dur', m['dur'], [(g['path'], g['t0'], g['t1'], g['skip']) for g in m['segs']])"
curl -s -X POST -H "X-FPV: 1" -H "Content-Type: application/json" -d "{\"do\":\"delete\",\"id\":\"$(basename $D)\"}" http://localhost:8080/api/rec; echo; echo "drives kept: $N0"
