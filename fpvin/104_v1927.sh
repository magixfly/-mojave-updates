#timeout 200
echo "--- clean up the AT test of 101/103 (option driver off the stick) ---"
echo "1286 4e31" > /sys/bus/usb-serial/drivers/option1/remove_id 2>/dev/null; rmmod option 2>/dev/null; rmmod usb_wwan 2>/dev/null; ls /dev/ttyUSB* 2>&1 | head -2
T=$(mktemp -d); curl -fsSL https://raw.githubusercontent.com/magixfly/-mojave-updates/carlin/fpv/fpv_pi_V1.9.27.tar.gz -o $T/p.tgz && tar -xzf $T/p.tgz -C $T 2>/dev/null
cp $T/pi/*.py $T/pi/usbcam.sh /opt/fpv/ && rm -rf /opt/fpv/cockpit && cp -r $T/pi/cockpit /opt/fpv/ && cp -r $T/pi/. /boot/firmware/pi/
systemctl restart fpv-bridge fpv-stickpage; sleep 8
grep -m1 VERSION /opt/fpv/fpvcfg.py; systemctl is-active fpv-bridge fpv-mediamtx fpv-stickpage
journalctl -u fpv-bridge -n 6 --no-pager | cut -c1-140
curl -s -m 5 -o /dev/null -w "cockpit: http %{http_code}, %{size_download} bytes\n" http://localhost:8080/
curl -s -m 5 http://localhost:8080/api/lte; echo
curl -s -m 8 -o /dev/null -w "stick page through the Pi: http %{http_code}\n" http://127.0.0.1:8081/
systemd-run --on-active=20 --unit=fpv-remote-restart-104 systemctl restart fpv-remote >/dev/null 2>&1 && echo "remote restart scheduled"
echo "[100%] done"
