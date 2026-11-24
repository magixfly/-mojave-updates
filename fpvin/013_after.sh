#timeout 60
uptime; grep -m1 VERSION /opt/fpv/fpvcfg.py
echo "--- video server"; journalctl -u fpv-mediamtx -b --no-pager -o cat | grep -E "path |ERR|WAR|usbcam" | tail -10 | cut -c1-190
echo "--- cameras"; ls /dev/v4l/by-id/ 2>&1; grep -nE "^  [a-z0-9]+:" /etc/fpv/mediamtx.yml
echo "--- holders"; fuser -v /dev/video0 2>&1 | tail -3; pgrep -a "gst|rpicam|ffmpeg" | cut -c1-90
vcgencmd measure_temp; vcgencmd get_throttled
