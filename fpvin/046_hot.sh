#timeout 200
Y=/etc/fpv/mediamtx.yml; cp $Y /tmp/mtx.bak2
curl -s -X POST -H "X-FPV: 1" -H "Content-Type: application/json" -d '{"on":false}' http://localhost:8080/api/emergency; echo
grep -E "rpiCamera(Width|FPS|Bitrate|IDRPeriod)" $Y | head -4 | tr -s ' ' | tr '\n' ';'; echo
meas() { # one reader for 16 s, prints bytes per 2 s; the change happens after 5 s
  ( timeout 18 ffmpeg -hide_banner -nostats -loglevel error -rtsp_transport tcp -i rtsp://localhost:8554/cam -t 16 -c copy -f h264 - 2>/tmp/ff.err | \
    python3 -c "
import sys,time
t0=time.time(); n=0; last=0; out=[]
while True:
    b=sys.stdin.buffer.read1(65536)
    if not b: break
    n+=len(b); t=time.time()-t0
    if int(t/2)>last: out.append(round(n*8/2000)); n=0; last=int(t/2)
print('kbit/s per 2 s:', out, 'ended after %.1f s' % (time.time()-t0))" ) &
  sleep 5.5; eval "$1"; wait; tail -1 /tmp/ff.err | cut -c1-120; }
echo "--- bitrate 4000 -> 500 (same size)"; meas "sed -i -E '0,/rpiCameraBitrate:/s/(rpiCameraBitrate: ).*/\1500000/' $Y"
echo "--- fps 30 -> 15 too"; meas "sed -i -E '0,/rpiCameraFPS:/s/(rpiCameraFPS: ).*/\115/' $Y"
journalctl -u fpv-mediamtx --since "-40s" --no-pager -o cat | grep -v "RTSP\]" | tail -6 | cut -c1-170
echo "--- back"; meas "cp /tmp/mtx.bak2 $Y"
