#timeout 420
D=$(ls /dev/v4l/by-id/usb-*-video-index0 | head -1); C=/boot/firmware/fpv-config.txt; DM0=$(dmesg | wc -l)
sed -i -E "s|^cam2_enable[[:space:]]*=.*|cam2_enable        = 0|" $C
python3 /opt/fpv/apply_config.py >/dev/null 2>&1; timeout 25 systemctl restart fpv-mediamtx; sleep 7
maincam() { timeout 8 ffprobe -v error -rtsp_transport tcp -count_packets -select_streams v:0 -show_entries stream=nb_read_packets -of csv=p=0 -read_intervals "%+4" rtsp://localhost:8554/cam 2>&1 | tail -1; }
run() { name=$1; shift; rm -f /tmp/t.h264 /tmp/t.log
  echo; echo "##### $name"
  timeout -s INT -k 4 13 "$@" > /tmp/t.log 2>&1 &
  sleep 8; cpu=$(top -b -n1 -w 200 | grep -E "gst-launch|ffmpeg" | awk '{s+=$9} END {print s+0}'); mc=$(maincam)
  wait; pkill -9 -f gst-launch 2>/dev/null; pkill -9 -f gst-plugin-scanner 2>/dev/null
  fr=$(timeout 10 ffprobe -v error -count_packets -select_streams v:0 -show_entries stream=nb_read_packets -of csv=p=0 /tmp/t.h264 2>/dev/null)
  echo "cpu ${cpu}%  frames ${fr:-0} (about 360 expected)   main camera meanwhile: ${mc} (120 expected)"
  grep -iE "error|warn|not-negotiated|failed|could not|invalid" /tmp/t.log | head -4 | cut -c1-220
  echo "kernel errors so far: $(dmesg | tail -n +$((DM0+1)) | grep -ciE 'timed out waiting|failed to create component')"; }
SRC="v4l2src device=$D ! image/jpeg,width=1920,height=1080,framerate=30/1"
ENC="v4l2h264enc extra-controls=controls,video_bitrate=3000000,h264_i_frame_period=30,repeat_sequence_header=1"
OUT="h264parse ! filesink location=/tmp/t.h264"
run "1080p A: chip decode, level 4.2" gst-launch-1.0 -e $SRC ! v4l2jpegdec ! "video/x-raw,format=I420" ! $ENC ! "video/x-h264,level=(string)4.2" ! $OUT
run "1080p B: chip decode, no format given, level 4.2" gst-launch-1.0 -e $SRC ! v4l2jpegdec ! $ENC ! "video/x-h264,level=(string)4.2" ! $OUT
run "1080p C: chip decode + converter" gst-launch-1.0 -e $SRC ! v4l2jpegdec ! v4l2convert ! "video/x-raw,format=I420,width=1920,height=1080" ! $ENC ! "video/x-h264,level=(string)4.2" ! $OUT
run "1080p D: software decode (gstreamer) + chip encode" gst-launch-1.0 -e $SRC ! jpegdec ! videoconvert ! "video/x-raw,format=I420" ! $ENC ! "video/x-h264,level=(string)4.2" ! $OUT
run "1080p E: ffmpeg as before" ffmpeg -hide_banner -loglevel warning -y -fflags nobuffer -flags low_delay -f v4l2 -input_format mjpeg -video_size 1920x1080 -framerate 30 -i $D -pix_fmt yuv420p -c:v h264_v4l2m2m -b:v 3000k -g 30 -bf 0 -t 11 -f h264 /tmp/t.h264
echo; echo "main camera after: $(maincam)"
sed -i -E "s|^cam2_enable[[:space:]]*=.*|cam2_enable        = 1|" $C
python3 /opt/fpv/apply_config.py 2>&1 | tail -1; timeout 25 systemctl restart fpv-mediamtx
vcgencmd measure_temp; rm -f /tmp/t.h264 /tmp/t.log
