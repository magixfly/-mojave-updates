#timeout 60
ls /run/fpv-usbcam-* 2>/dev/null || echo "no fallback markers"
pgrep -af "gst-launch|ffmpeg|usbcam.sh" | cut -c1-150
journalctl -u fpv-mediamtx --since "-25min" --no-pager -o short | grep -E "usbcam\]|path cam2|ERR|WAR" | grep -v "session\|RTSP\] \[conn" | tail -45 | cut -c8-200
