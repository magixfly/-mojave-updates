#timeout 200
echo "--- state before"; uptime | sed 's/.*load/load/'; vcgencmd measure_temp; vcgencmd get_throttled; free -m | sed -n 2p
iw dev wlan0 link 2>/dev/null | grep -E "SSID|freq|signal|bitrate" | tr -s ' \t' ' ' | tr '\n' ';'; echo
grep -E "rpiCamera(Width|FPS|Bitrate|IDRPeriod)" /etc/fpv/mediamtx.yml | head -4 | tr -s ' ' | tr '\n' ';'; echo
top -bn1 -o %CPU | sed -n 8,13p | cut -c1-110
T=$(mktemp -d); curl -fsSL https://raw.githubusercontent.com/magixfly/-mojave-updates/carlin/fpv/fpv_pi_V1.8.9.tar.gz -o $T/p.tgz && tar -xzf $T/p.tgz -C $T 2>/dev/null
cp $T/pi/*.py $T/pi/usbcam.sh /opt/fpv/ && rm -rf /opt/fpv/cockpit && cp -r $T/pi/cockpit /opt/fpv/ && cp -r $T/pi/. /boot/firmware/pi/
python3 /opt/fpv/apply_config.py >/dev/null; timeout 25 systemctl restart fpv-mediamtx; systemctl restart fpv-bridge; sleep 7
echo "--- after"; grep -m1 VERSION /opt/fpv/fpvcfg.py; systemctl is-active fpv-bridge fpv-mediamtx; grep -c "CloseAfter: 10s" /etc/fpv/mediamtx.yml; curl -s http://localhost:8080/api/paths; echo
echo "[100%] done"
