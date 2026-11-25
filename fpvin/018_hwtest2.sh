#timeout 420
echo "gpu memory now: $(vcgencmd get_mem gpu), free RAM: $(free -m | awk 'NR==2{print $7}') MB"
D=$(ls /dev/v4l/by-id/usb-*-video-index0 | head -1); echo "camera: $D"
C=/boot/firmware/fpv-config.txt; DM0=$(dmesg | wc -l)
# main camera keeps running; the USB path is switched off for the test so nobody else opens the camera
sed -i -E "s|^cam2_enable[[:space:]]*=.*|cam2_enable        = 0|" $C
python3 /opt/fpv/apply_config.py >/dev/null 2>&1; timeout 25 systemctl restart fpv-mediamtx; sleep 7
maincam() { timeout 8 ffprobe -v error -rtsp_transport tcp -count_packets -select_streams v:0 -show_entries stream=nb_read_packets -of csv=p=0 -read_intervals "%+4" rtsp://localhost:8554/cam 2>&1 | tail -1; }
echo "main camera before: $(maincam) pictures in 4 s"
run() { name=$1; W=$2; H=$3; K=$4; rm -f /tmp/t.h264 /tmp/t.log
  echo; echo "##### $name ${W}x${H}"
  timeout -s INT -k 4 13 gst-launch-1.0 -e v4l2src device=$D ! "image/jpeg,width=$W,height=$H,framerate=30/1" ! v4l2jpegdec ! "video/x-raw,format=I420" ! v4l2h264enc extra-controls=controls,video_bitrate=${K}000,h264_i_frame_period=30,repeat_sequence_header=1 ! "video/x-h264,level=(string)4" ! h264parse ! filesink location=/tmp/t.h264 > /tmp/t.log 2>&1 &
  sleep 8; cpu=$(top -b -n1 -w 200 | grep -E "gst-launch" | awk '{s+=$9} END {print s+0}'); mc=$(maincam)
  wait; echo "ended with code $?"; pkill -9 -f gst-launch 2>/dev/null; pkill -9 -f gst-plugin-scanner 2>/dev/null
  fr=$(timeout 10 ffprobe -v error -count_packets -select_streams v:0 -show_entries stream=nb_read_packets -of csv=p=0 /tmp/t.h264 2>/dev/null)
  echo "USB camera: cpu ${cpu}%  frames ${fr:-0} (about 360 expected)   main camera meanwhile: ${mc} pictures in 4 s (120 expected)"
  grep -vE "^Setting pipeline|^Pipeline is|^New clock|^Redistribute|^handling|^Interrupt|^EOS|^Waiting|^Got EOS|^Execution|^Freeing" /tmp/t.log | tail -4 | cut -c1-200
  echo "kernel errors so far: $(dmesg | tail -n +$((DM0+1)) | grep -ciE 'timed out waiting|failed to create component')"; }
run "hardware way" 1280 720 1500
run "hardware way" 1920 1080 3000
run "hardware way again (does the chip recover after stopping?)" 1280 720 1500
echo; echo "main camera after: $(maincam) pictures in 4 s"
dmesg | tail -n +$((DM0+1)) | grep -iE "error|fail|timed out|mmal|not enough" | tail -6 | cut -c1-170
sed -i -E "s|^cam2_enable[[:space:]]*=.*|cam2_enable        = 1|" $C
python3 /opt/fpv/apply_config.py 2>&1 | tail -1; timeout 25 systemctl restart fpv-mediamtx
vcgencmd measure_temp; vcgencmd get_throttled; rm -f /tmp/t.h264 /tmp/t.log
