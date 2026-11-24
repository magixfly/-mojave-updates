D=$(ls /dev/v4l/by-id/usb-Microsoft*-video-index0 | head -1); echo "test camera: $D"
v4l2-ctl -d "$D" -L 2>&1 | grep -iE "dynamic|priority|power_line" | cut -c1-120
v4l2-ctl -d "$D" -c power_line_frequency=1 2>&1; v4l2-ctl -d "$D" -c exposure_dynamic_framerate=0 2>&1
run() { echo; echo "##### $1"; shift
  timeout 14 "$@" > /tmp/gst.log 2>&1 &
  sleep 9; echo "cpu of the pipeline:"; top -b -n1 -w 200 | grep -E "gst-launch|ffmpeg" | awk '{print $9"% "$12" "$13" "$14}' | cut -c1-80
  wait; tail -4 /tmp/gst.log | cut -c1-220
  journalctl -u fpv-mediamtx --since "-16s" --no-pager -o cat | grep -E "cam3|ERR|WAR" | tail -4 | cut -c1-170; }
ENC='v4l2h264enc extra-controls=controls,video_bitrate=1500000,h264_i_frame_period=30,repeat_sequence_header=1'
run "A hardware jpeg decode" gst-launch-1.0 -q v4l2src device=$D ! image/jpeg,width=1280,height=720,framerate=30/1 ! v4l2jpegdec ! $ENC ! 'video/x-h264,level=(string)4' ! h264parse config-interval=-1 ! rtspclientsink location=rtsp://localhost:8554/cam3 protocols=tcp latency=0
run "B software jpeg decode" gst-launch-1.0 -q v4l2src device=$D ! image/jpeg,width=1280,height=720,framerate=30/1 ! jpegdec ! videoconvert ! video/x-raw,format=I420 ! $ENC ! 'video/x-h264,level=(string)4' ! h264parse config-interval=-1 ! rtspclientsink location=rtsp://localhost:8554/cam3 protocols=tcp latency=0
run "C ffmpeg low delay" ffmpeg -hide_banner -loglevel warning -fflags nobuffer -flags low_delay -probesize 32 -analyzeduration 0 -f v4l2 -input_format mjpeg -video_size 1280x720 -framerate 30 -i $D -pix_fmt yuv420p -c:v h264_v4l2m2m -b:v 1500k -g 30 -bf 0 -f rtsp -rtsp_transport tcp rtsp://localhost:8554/cam3
echo; uptime; vcgencmd measure_temp
