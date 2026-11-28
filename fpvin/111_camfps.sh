#timeout 90
echo "=== config.txt camera lines ==="; grep -nE "dtoverlay|camera_auto|dtparam=i2c" /boot/firmware/config.txt
echo "=== dmesg imx290 ==="; dmesg | grep -iE "imx290|imx462|unicam" | tail -8
echo "=== real frame rate of path cam (10 s) ==="
timeout 25 ffprobe -v error -rtsp_transport tcp -select_streams v -count_packets -read_intervals "%+10" -show_entries stream=nb_read_packets,r_frame_rate,avg_frame_rate,width,height -of default=nw=1 rtsp://127.0.0.1:8554/cam 2>&1 | head
echo "=== mediamtx log about camera ==="; journalctl -u fpv-mediamtx --no-pager -n 300 | grep -iE "rpicam|fps|frame|mode|camera" | tail -8 | cut -c1-200
echo "=== options in mediamtx docs inside binary ==="; strings /opt/fpv/mediamtx | grep -oE "rpiCamera[A-Z][A-Za-z0-9]+" | sort -u | tr '\n' ' '; echo
echo "[100%] done"
