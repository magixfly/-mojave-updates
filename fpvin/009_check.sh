grep -m1 VERSION /opt/fpv/fpvcfg.py; grep -nE "^  [a-z0-9]+:|usbcam" /etc/fpv/mediamtx.yml | cut -c1-200
echo "--- pipelines"; journalctl -u fpv-mediamtx --since "-6min" --no-pager -o cat | grep -E "usbcam|ERR|WAR|erroneous|cam[234]\]" | tail -16 | cut -c1-210
echo "--- cpu"; top -b -n1 -w 200 | grep -E "gst-launch|ffmpeg|mediamtx" | awk '{print $9"% "$12}'
for f in /run/fpv-usbcam-*; do [ -e "$f" ] && echo "$f: $(cat $f)"; done; uptime; vcgencmd measure_temp; lsusb | grep -iE "cam|webcam"
