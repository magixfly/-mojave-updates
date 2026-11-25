#timeout 300
echo "[30%] installing V1.7.3"
T=$(mktemp -d); curl -fsSL https://raw.githubusercontent.com/magixfly/-mojave-updates/carlin/fpv/fpv_pi_V1.7.3.tar.gz -o $T/p.tgz && tar -xzf $T/p.tgz -C $T
cp $T/pi/*.py $T/pi/usbcam.sh /opt/fpv/ && rm -rf /opt/fpv/cockpit && cp -r $T/pi/cockpit /opt/fpv/ && cp -r $T/pi/. /boot/firmware/pi/
systemctl restart fpv-bridge; sleep 6
echo "[90%] checking"
grep -m1 VERSION /opt/fpv/fpvcfg.py; systemctl is-active fpv-bridge fpv-mediamtx
curl -s http://localhost:8080/ | grep -c "pibar\|expdlg"
curl -s http://localhost:8080/api/status | python3 -c "import sys,json;d=json.load(sys.stdin);print({k:d.get(k) for k in ('v','fc_ok')})"
curl -s http://localhost:8080/api/paths
echo "[100%] done"
