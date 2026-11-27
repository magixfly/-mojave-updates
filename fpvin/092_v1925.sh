#timeout 240
T=$(mktemp -d); curl -fsSL https://raw.githubusercontent.com/magixfly/-mojave-updates/carlin/fpv/fpv_pi_V1.9.25.tar.gz -o $T/p.tgz && tar -xzf $T/p.tgz -C $T 2>/dev/null
cp $T/pi/*.py $T/pi/usbcam.sh /opt/fpv/ && rm -rf /opt/fpv/cockpit && cp -r $T/pi/cockpit /opt/fpv/ && cp -r $T/pi/. /boot/firmware/pi/
systemctl restart fpv-bridge; sleep 7
grep -m1 VERSION /opt/fpv/fpvcfg.py; systemctl is-active fpv-bridge fpv-mediamtx fpv-stickpage
echo "[40%] network order: Wi-Fi first, LTE stick second"
echo "== before"; ip -4 route show default; nmcli -t -f DEVICE,STATE,CONNECTION dev | grep -E "^(eth|wlan|usb)"
DEV=""; for i in /sys/class/net/*; do if readlink -f $i/device 2>/dev/null | grep -q /usb; then DEV=$(basename $i); break; fi; done
echo "stick interface: ${DEV:-none}"
if [ -n "$DEV" ]; then
  OLD=$(nmcli -g GENERAL.CONNECTION dev show $DEV)
  nmcli con delete fpv-lte >/dev/null 2>&1
  nmcli con add type ethernet con-name fpv-lte ifname '*' match.driver "rndis_host cdc_ether cdc_ncm" \
    ipv4.route-metric 700 ipv6.route-metric 700 connection.autoconnect yes connection.autoconnect-priority 50 2>&1 | tail -1
  nmcli con up fpv-lte ifname $DEV 2>&1 | tail -1
  sleep 6
  NOW=$(nmcli -g GENERAL.CONNECTION dev show $DEV)
  if [ "$NOW" = "fpv-lte" ] && ping -c 3 -W 3 -I $DEV -q 1.1.1.1 >/dev/null 2>&1; then
    echo "stick profile fpv-lte active, internet through $DEV works"
  else
    echo "NOT OK (now: '$NOW') - going back to '$OLD'"
    nmcli con delete fpv-lte 2>&1 | tail -1; nmcli dev connect $DEV 2>&1 | tail -1; sleep 5
  fi
fi
echo "== after"; ip -4 route show default; nmcli -t -f DEVICE,STATE,CONNECTION dev | grep -E "^(eth|wlan|usb)"
sleep 6; echo "== cockpit sees"; curl -s http://localhost:8080/api/net; echo
ping -c 3 -q 1.1.1.1 | tail -1
echo "[100%] done"
