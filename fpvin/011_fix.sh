#timeout 90
echo "--- stuck processes"; pgrep -a "gst|ffmpeg" | cut -c1-120
pkill -9 -f gst-inspect; pkill -9 -f gst-launch; pkill -9 -f gst-plugin-scanner; pkill -9 -f usbcam.sh; pkill -9 ffmpeg; sleep 1
echo "--- who holds the cameras"; fuser -v /dev/video0 /dev/video1 /dev/video3 2>&1 | tail -6
rm -f /run/fpv-usbcam-*
grep -E "^cam2_" /boot/firmware/fpv-config.txt
systemctl restart fpv-mediamtx; sleep 8
echo "--- video server"; journalctl -u fpv-mediamtx --since "-9s" --no-pager -o cat | grep -vE "^\[.*INFO (Camera|IPAProxy|RPI)" | tail -12 | cut -c1-190
ls /dev/v4l/by-id/ 2>&1; vcgencmd measure_temp
