echo "--- USB devices"; lsusb
echo "--- video devices"; ls -l /dev/v4l/by-id/ 2>&1
CAM=$(ls /dev/v4l/by-id/usb-*-video-index0 2>/dev/null | head -1)
if [ -n "$CAM" ]; then echo "--- formats of $CAM"; v4l2-ctl -d "$CAM" --list-formats-ext 2>&1 | grep -E "^\s+\[|Size|Interval" | head -40; fi
echo "--- microphones"; arecord -l 2>&1
sed -i 's/^cam2_enable .*/cam2_enable        = 1/' /boot/firmware/fpv-config.txt
grep -E '^(cam2_|audio_)' /boot/firmware/fpv-config.txt
python3 /opt/fpv/apply_config.py
systemctl restart fpv-mediamtx; sleep 3
echo "--- mediamtx paths"; grep -nE "^  [a-z0-9]+:|ffmpeg|input_format|video_size" /etc/fpv/mediamtx.yml
journalctl -u fpv-mediamtx -n 8 --no-pager -o cat
