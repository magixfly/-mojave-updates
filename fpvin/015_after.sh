#timeout 40
uptime; journalctl -u fpv-mediamtx -b --no-pager -o cat | grep -E "path cam|usbcam|ERR" | tail -5 | cut -c1-170
dmesg | grep -ciE "timed out waiting|failed to create component"; pgrep -a "gst|rpicam-hello" | cut -c1-60
vcgencmd get_mem gpu; vcgencmd measure_temp; vcgencmd get_throttled; grep -E "^cam2_(enable|width|height|pipeline)" /boot/firmware/fpv-config.txt
