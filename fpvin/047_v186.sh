#timeout 300
T=$(mktemp -d); curl -fsSL https://raw.githubusercontent.com/magixfly/-mojave-updates/carlin/fpv/fpv_pi_V1.8.6.tar.gz -o $T/p.tgz && tar -xzf $T/p.tgz -C $T
cp $T/pi/*.py $T/pi/usbcam.sh /opt/fpv/ && rm -rf /opt/fpv/cockpit && cp -r $T/pi/cockpit /opt/fpv/ && cp -r $T/pi/. /boot/firmware/pi/
C=/boot/firmware/fpv-config.txt; sed -i -E 's/^emergency_fps[[:space:]]*=.*/emergency_fps          = 15/; s/^emergency_bitrate_kbps[[:space:]]*=.*/emergency_bitrate_kbps = 400/; /^emergency_(width|height)/d' $C
systemctl restart fpv-bridge; sleep 6
grep -m1 VERSION /opt/fpv/fpvcfg.py; systemctl is-active fpv-bridge fpv-mediamtx
P() { curl -s -X POST -H "X-FPV: 1" -H "Content-Type: application/json" -d "$1" http://localhost:8080/api/emergency; echo; }
P '{"on":false}' >/dev/null; sleep 2
( timeout 26 ffmpeg -hide_banner -nostats -loglevel error -rtsp_transport tcp -i rtsp://localhost:8554/cam -t 24 -c copy -f h264 - 2>/dev/null | python3 -c "
import sys,time
t0=time.time(); n=0; last=0; out=[]
while True:
    b=sys.stdin.buffer.read1(65536)
    if not b: break
    n+=len(b); t=time.time()-t0
    if int(t/2)>last: out.append(round(n*8/2000)); n=0; last=int(t/2)
print('one reader, kbit/s per 2 s:', out, 'ended after %.1f s' % (time.time()-t0))" ) &
sleep 6; P '{"on":true}'; sleep 9; P '{"on":false}'; wait
timeout 8 ffprobe -v error -rtsp_transport tcp -select_streams v:0 -show_entries stream=width,height,avg_frame_rate -of csv=p=0 rtsp://localhost:8554/cam | head -1
free -m | sed -n 2p; vcgencmd measure_temp; vcgencmd get_throttled; uptime | sed 's/.*load/load/'
echo "[100%] done"
