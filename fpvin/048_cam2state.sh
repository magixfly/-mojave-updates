#timeout 60
ls /run/fpv-usbcam-* 2>/dev/null || echo "no fallback markers"
journalctl -u fpv-mediamtx --since "-6min" --no-pager -o short | grep -E "usbcam\]|path cam2|runOnDemand" | tail -14 | cut -c8-190
pgrep -af "gst-launch|ffmpeg" | cut -c1-140
