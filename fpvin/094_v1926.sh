#timeout 200
T=$(mktemp -d); curl -fsSL https://raw.githubusercontent.com/magixfly/-mojave-updates/carlin/fpv/fpv_pi_V1.9.26.tar.gz -o $T/p.tgz && tar -xzf $T/p.tgz -C $T 2>/dev/null
cp $T/pi/*.py $T/pi/usbcam.sh /opt/fpv/ && rm -rf /opt/fpv/cockpit && cp -r $T/pi/cockpit /opt/fpv/ && cp -r $T/pi/. /boot/firmware/pi/
systemctl restart fpv-bridge fpv-stickpage; sleep 7
grep -m1 VERSION /opt/fpv/fpvcfg.py; systemctl is-active fpv-bridge fpv-mediamtx fpv-stickpage
journalctl -u fpv-stickpage -n 1 --no-pager | cut -c1-140
curl -s -m 8 -o /dev/null -w "stick page through the Pi: http %{http_code} %{size_download} bytes\n" http://127.0.0.1:8081/
curl -s http://localhost:8080/api/net; echo
echo "[100%] done"
