#timeout 200
T=$(mktemp -d); curl -fsSL https://raw.githubusercontent.com/magixfly/-mojave-updates/carlin/fpv/fpv_pi_V1.9.14.tar.gz -o $T/p.tgz && tar -xzf $T/p.tgz -C $T 2>/dev/null
cp $T/pi/*.py $T/pi/usbcam.sh /opt/fpv/ && rm -rf /opt/fpv/cockpit && cp -r $T/pi/cockpit /opt/fpv/ && cp -r $T/pi/. /boot/firmware/pi/
for i in 1 2 3; do curl -s http://localhost:8080/api/rec | python3 -c "import sys,json;d=json.load(sys.stdin);print('before', json.dumps(d.get('cockpit')))"; sleep 3; done
systemctl restart fpv-bridge; sleep 7
grep -m1 VERSION /opt/fpv/fpvcfg.py; systemctl is-active fpv-bridge fpv-mediamtx; curl -s http://localhost:8080/ | grep -c "hid: document.hidden"
echo "[100%] done"
