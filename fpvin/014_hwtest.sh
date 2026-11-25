#timeout 420
D=$(ls /dev/v4l/by-id/usb-*-video-index0 | head -1); echo "camera: $D"
C=/boot/firmware/fpv-config.txt
DM0=$(dmesg | wc -l)
W=1280; H=720
ENC="v4l2h264enc extra-controls=controls,video_bitrate=1500000,h264_i_frame_period=30,repeat_sequence_header=1"
run() { name=$1; shift; rm -f /tmp/t.h264 /tmp/t.log
  echo; echo "##### $name"
  timeout -s KILL 13 "$@" > /tmp/t.log 2>&1 &
  sleep 9; cpu=$(top -b -n1 -w 200 | grep -E "gst-launch|ffmpeg" | awk '{s+=$9} END {print s+0}')
  wait; pkill -9 -f gst-launch 2>/dev/null; pkill -9 -f gst-plugin-scanner 2>/dev/null
  sz=$(stat -c %s /tmp/t.h264 2>/dev/null || echo 0)
  fr=$(timeout 10 ffprobe -v error -count_packets -select_streams v:0 -show_entries stream=nb_read_packets -of csv=p=0 /tmp/t.h264 2>/dev/null)
  echo "cpu ${cpu}%  file ${sz} bytes  frames ${fr:-0} (in about 12 s, 360 would be perfect)"
  grep -vE "^Setting pipeline|^Pipeline is|^New clock|^Redistribute" /tmp/t.log | tail -5 | cut -c1-230; }
phase() {
run "A hardware decode + hardware encode" gst-launch-1.0 -e v4l2src device=$D ! "image/jpeg,width=$W,height=$H,framerate=30/1" ! v4l2jpegdec ! $ENC ! "video/x-h264,level=(string)4" ! h264parse ! filesink location=/tmp/t.h264
run "B same with fixed picture format" gst-launch-1.0 -e v4l2src device=$D ! "image/jpeg,width=$W,height=$H,framerate=30/1" ! v4l2jpegdec ! "video/x-raw,format=I420" ! $ENC ! "video/x-h264,level=(string)4" ! h264parse ! filesink location=/tmp/t.h264
run "C software decode (gstreamer)" gst-launch-1.0 -e v4l2src device=$D ! "image/jpeg,width=$W,height=$H,framerate=30/1" ! jpegdec ! videoconvert ! "video/x-raw,format=I420" ! $ENC ! "video/x-h264,level=(string)4" ! h264parse ! filesink location=/tmp/t.h264
run "D ffmpeg (what runs now)" ffmpeg -hide_banner -loglevel warning -y -fflags nobuffer -flags low_delay -f v4l2 -input_format mjpeg -video_size ${W}x${H} -framerate 30 -i $D -pix_fmt yuv420p -c:v h264_v4l2m2m -b:v 1500k -g 30 -bf 0 -t 11 -f h264 /tmp/t.h264
}
echo "================ PHASE 1: video server stopped"
timeout 20 systemctl stop fpv-mediamtx; sleep 2; pkill -9 ffmpeg 2>/dev/null
phase
echo; echo "================ PHASE 2: main camera running, USB camera free"
sed -i -E "s|^cam2_enable[[:space:]]*=.*|cam2_enable        = 0|" $C
python3 /opt/fpv/apply_config.py >/dev/null 2>&1; timeout 20 systemctl start fpv-mediamtx; sleep 6
journalctl -u fpv-mediamtx --since "-7s" --no-pager -o cat | grep -E "path cam\]" | tail -2 | cut -c1-120
phase
echo; echo "================ CLEAN-UP AND CHECK"
sed -i -E "s|^cam2_enable[[:space:]]*=.*|cam2_enable        = 1|" $C
python3 /opt/fpv/apply_config.py 2>&1 | tail -1
echo "left-over processes:"; pgrep -a "gst|rpicam-hello" | cut -c1-80; echo "(end of list)"
echo "new kernel messages:"; dmesg | tail -n +$((DM0+1)) | grep -iE "error|fail|warn|oops|timeout|bcm2835|v4l2|uvc" | tail -12 | cut -c1-170; echo "(end of list)"
echo "main camera still online:"; journalctl -u fpv-mediamtx --since "-90s" --no-pager -o cat | grep -E "ERR|closed|path cam\]" | tail -4 | cut -c1-150
vcgencmd measure_temp; vcgencmd get_throttled; rm -f /tmp/t.h264 /tmp/t.log
systemd-run --quiet --on-active=10 systemctl reboot; echo "reboot in 10 s"
