#timeout 90
T=$(mktemp -d); curl -fsSL https://raw.githubusercontent.com/magixfly/-mojave-updates/carlin/fpv/fpv_pi_V1.4.5.tar.gz -o $T/p.tgz && tar -xzf $T/p.tgz -C $T
cp $T/pi/*.py $T/pi/usbcam.sh /opt/fpv/ && rm -rf /opt/fpv/cockpit && cp -r $T/pi/cockpit /opt/fpv/ && cp -r $T/pi/. /boot/firmware/pi/
rm -f /run/fpv-usbcam-*; systemctl restart fpv-bridge
grep -m1 VERSION /opt/fpv/fpvcfg.py; lsusb | grep -viE "hub" || echo "no USB camera plugged in"
python3 /opt/fpv/apply_config.py | tail -1; grep -nE "^  [a-z0-9]+:" /etc/fpv/mediamtx.yml
