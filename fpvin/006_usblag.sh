echo "--- readers"; journalctl -u fpv-mediamtx -n 12 --no-pager -o cat | cut -c1-170
echo "--- ffmpeg running"; pgrep -a ffmpeg | cut -c1-260
for D in /dev/v4l/by-id/usb-*-video-index0; do
  echo "=== $D"; v4l2-ctl -d "$D" -L 2>&1 | grep -iE "exposure|framerate|priority|power_line|gain |backlight" | cut -c1-150
  if ! fuser "$D" >/dev/null 2>&1; then
    v4l2-ctl -d "$D" --set-fmt-video=width=1280,height=720,pixelformat=MJPG --set-parm=30 >/dev/null 2>&1
    echo "fps as is:"; timeout 6 v4l2-ctl -d "$D" --stream-mmap --stream-count=45 2>&1 | tr '\r' '\n' | grep -oE "[0-9.]+ fps" | tail -1
    for c in exposure_dynamic_framerate exposure_auto_priority; do v4l2-ctl -d "$D" -c $c=0 2>/dev/null && echo "set $c=0"; done
    echo "fps with fixed frame rate:"; timeout 6 v4l2-ctl -d "$D" --stream-mmap --stream-count=45 2>&1 | tr '\r' '\n' | grep -oE "[0-9.]+ fps" | tail -1
  else echo "(in use right now - not measured)"; fi
done
echo "--- gstreamer parts"; for e in v4l2src jpegdec v4l2h264enc v4l2jpegdec h264parse rtspclientsink; do gst-inspect-1.0 $e >/dev/null 2>&1 && echo "ok $e" || echo "MISSING $e"; done
echo "--- load"; uptime; vcgencmd measure_temp
