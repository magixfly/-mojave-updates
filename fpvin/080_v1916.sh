#timeout 200
T=$(mktemp -d); curl -fsSL https://raw.githubusercontent.com/magixfly/-mojave-updates/carlin/fpv/fpv_pi_V1.9.16.tar.gz -o $T/p.tgz && tar -xzf $T/p.tgz -C $T 2>/dev/null
echo "drives before: $(ls /var/lib/fpv/rec | wc -l)"
cp $T/pi/*.py $T/pi/usbcam.sh /opt/fpv/ && rm -rf /opt/fpv/cockpit && cp -r $T/pi/cockpit /opt/fpv/ && cp -r $T/pi/. /boot/firmware/pi/
systemctl restart fpv-bridge; sleep 7
grep -m1 VERSION /opt/fpv/fpvcfg.py; systemctl is-active fpv-bridge fpv-mediamtx; curl -s http://localhost:8080/ | grep -c "function recSweep"
echo "drives after: $(ls /var/lib/fpv/rec | wc -l)"; journalctl -u fpv-bridge --since "-20s" --no-pager | grep -c "long - deleted"
curl -s http://localhost:8080/api/rec | python3 -c "import sys,json;d=json.load(sys.stdin);print('min_s',d.get('min_s'),[round(m['dur']/1000) for m in d['list']])"
echo "[100%] done"
