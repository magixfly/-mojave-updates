#timeout 300
pkill -9 -f gst-inspect; pkill -9 -f gst-launch; pkill -9 -f gst-plugin-scanner; pkill -9 rpicam-hello
C=/boot/firmware/fpv-config.txt
sed -i -E "s|^cam2_pipeline[[:space:]]*=.*|cam2_pipeline = auto|" $C
curl -fsSL https://raw.githubusercontent.com/magixfly/-mojave-updates/carlin/fpv/setup.sh | timeout 200 bash -s V1.4.2 2>&1 | tail -2
grep -m1 VERSION /opt/fpv/fpvcfg.py; grep -c rpicam-hello /opt/fpv/settings.py
systemd-run --quiet --on-active=6 systemctl reboot
echo "reboot in 6 s"
