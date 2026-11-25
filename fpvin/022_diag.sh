#timeout 60
echo "--- usb"; lsusb | grep -viE "hub"; ls /dev/v4l/by-id/ 2>&1
echo "--- config"; grep -E "^cam2_" /boot/firmware/fpv-config.txt; grep -nE "^  [a-z0-9]+:|usbcam" /etc/fpv/mediamtx.yml | cut -c1-160
echo "--- state"; ls -la /run/fpv-usbcam-* 2>&1; pgrep -a "gst|ffmpeg|usbcam" | cut -c1-110
echo "--- video server, last 5 min"; journalctl -u fpv-mediamtx --since "-5min" --no-pager -o cat | grep -vE "INFO (Camera|IPAProxy|RPI)" | tail -30 | cut -c1-210
echo "--- kernel"; dmesg | grep -iE "timed out waiting|failed to create|uvc|usb 1-1\.[0-9]: (USB disconnect|new)" | tail -8 | cut -c1-160
vcgencmd get_mem gpu; vcgencmd measure_temp; uptime
