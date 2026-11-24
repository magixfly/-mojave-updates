echo "--- USB"; lsusb
echo "--- kernel"; dmesg | grep -iE "usb [0-9-]+:|uvc|video|over-current|under-voltage" | tail -25
echo "--- v4l"; ls -l /dev/v4l/by-id/ 2>&1; v4l2-ctl --list-devices 2>&1 | head -40
for CAM in /dev/v4l/by-id/usb-*-video-index0; do [ -e "$CAM" ] || continue; echo "--- formats $CAM"; v4l2-ctl -d "$CAM" --list-formats-ext 2>&1 | grep -E "^\s+\[|Size" | head -24; done
echo "--- mics"; arecord -l 2>&1 | grep -E "^card" 
echo "--- power"; vcgencmd get_throttled
python3 /opt/fpv/apply_config.py; systemctl restart fpv-mediamtx; sleep 2
grep -nE "^  [a-z0-9]+:" /etc/fpv/mediamtx.yml
