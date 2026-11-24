C=/boot/firmware/fpv-config.txt
setkey() { if grep -qE "^$1[[:space:]]*=" $C; then sed -i -E "s|^$1[[:space:]]*=.*|$1 = $2|" $C; else echo "$1 = $2" >> $C; fi; }
setkey cam2_pipeline ffmpeg; setkey cam2_width 1280; setkey cam2_height 720; setkey cam2_bitrate_kbps 1500
rm -f /run/fpv-usbcam-*
python3 /opt/fpv/apply_config.py; systemctl restart fpv-mediamtx; sleep 14
journalctl -u fpv-mediamtx --since "-14s" --no-pager -o cat | grep -E "usbcam|cam2\]|ERR" | tail -6 | cut -c1-200
top -b -n1 -w 200 | grep -E "gst-launch|ffmpeg" | awk '{print $9"% "$12}'; vcgencmd measure_temp
echo "--- gst debug (camera must be free for this part)"
D=$(ls /dev/v4l/by-id/usb-EMEET*-video-index0 | head -1)
gst-inspect-1.0 v4l2jpegdec 2>&1 | grep -A12 "SINK template" | head -16
gst-inspect-1.0 v4l2h264enc 2>&1 | grep -A6 "SINK template" | head -10
