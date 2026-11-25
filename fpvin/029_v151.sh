#timeout 90
T=$(mktemp -d); curl -fsSL https://raw.githubusercontent.com/magixfly/-mojave-updates/carlin/fpv/fpv_pi_V1.5.1.tar.gz -o $T/p.tgz && tar -xzf $T/p.tgz -C $T
cp $T/pi/*.py $T/pi/usbcam.sh /opt/fpv/ && rm -rf /opt/fpv/cockpit && cp -r $T/pi/cockpit /opt/fpv/ && cp -r $T/pi/. /boot/firmware/pi/
systemctl restart fpv-bridge; sleep 2; grep -m1 VERSION /opt/fpv/fpvcfg.py; systemctl is-active fpv-bridge fpv-mediamtx; grep -c "showCams(all); startVideo" /opt/fpv/cockpit/index.html
