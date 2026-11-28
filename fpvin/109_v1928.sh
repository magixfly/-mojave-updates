#timeout 200
T=$(mktemp -d); curl -fsSL https://raw.githubusercontent.com/magixfly/-mojave-updates/carlin/fpv/fpv_pi_V1.9.28.tar.gz -o $T/p.tgz && tar -xzf $T/p.tgz -C $T 2>/dev/null
cp $T/pi/*.py $T/pi/usbcam.sh /opt/fpv/ && rm -rf /opt/fpv/cockpit && cp -r $T/pi/cockpit /opt/fpv/ && cp -r $T/pi/. /boot/firmware/pi/
systemctl restart fpv-bridge; sleep 12
grep -m1 VERSION /opt/fpv/fpvcfg.py; systemctl is-active fpv-bridge fpv-mediamtx fpv-stickpage
journalctl -u fpv-bridge -n 4 --no-pager | cut -c1-140
curl -s -m 5 -o /dev/null -w "cockpit: http %{http_code}\n" http://localhost:8080/
for i in 1 2 3; do echo "lte: $(curl -s -m 5 http://localhost:8080/api/lte | python3 -c 'import sys,json;d=json.load(sys.stdin);d.pop("raw",None);d.pop("user",None);print(d)')"; sleep 4; done
systemd-run --on-active=20 --unit=fpv-remote-restart-109 systemctl restart fpv-remote >/dev/null 2>&1 && echo "remote restart scheduled"
echo "[100%] done"
