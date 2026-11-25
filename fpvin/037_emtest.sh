#timeout 120
Y=/etc/fpv/mediamtx.yml; cp $Y /tmp/mtx.bak
probe() { timeout 12 ffprobe -v error -rtsp_transport tcp -select_streams v:0 -show_entries stream=width,height -of csv=p=0 rtsp://localhost:8554/cam 2>&1 | head -1; }
echo "start: $(probe)"; grep -n "rpiCameraWidth\|rpiCameraHeight\|rpiCameraBitrate\|rpiCameraFPS\|^api" $Y
echo "--- A: bitrate only"; T0=$(date +%s.%N)
sed -i -E 's/(rpiCameraBitrate: ).*/\1400000/' $Y; sleep 6
journalctl -u fpv-mediamtx --since "-7s" --no-pager -o short-precise | cut -c8-200 | tail -8
echo "--- B: size 640x360"; sed -i -E 's/(rpiCameraWidth: ).*/\1640/; s/(rpiCameraHeight: ).*/\1360/' $Y
S=$(date +%s.%N); for i in 1 2 3 4 5 6 7 8 9 10 11 12 13 14 15 16; do R=$(timeout 3 ffprobe -v error -rtsp_transport tcp -select_streams v:0 -show_entries stream=width,height -of csv=p=0 rtsp://localhost:8554/cam 2>/dev/null | head -1); if [ "$R" = "640,360" ]; then echo "640x360 readable after $(echo "$(date +%s.%N) - $S" | bc) s"; break; fi; sleep 0.3; done
journalctl -u fpv-mediamtx --since "-12s" --no-pager -o short-precise | cut -c8-200 | tail -10
timeout 8 ffmpeg -hide_banner -nostats -rtsp_transport tcp -i rtsp://localhost:8554/cam -t 4 -c copy -f null - 2>&1 | grep -E "frame=|bitrate=" | tail -1
echo "--- back"; cp /tmp/mtx.bak $Y; sleep 5; echo "end: $(probe)"
