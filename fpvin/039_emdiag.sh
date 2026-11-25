#timeout 120
Y=/etc/fpv/mediamtx.yml
P() { curl -s -X POST -H "X-FPV: 1" -H "Content-Type: application/json" -d "$1" http://localhost:8080/api/emergency; echo; }
V() { grep -E "rpiCamera(Width|Height|FPS|Bitrate|IDRPeriod)" $Y | head -5 | tr -s ' ' | tr '\n' ';'; echo; }
systemctl show fpv-mediamtx -p MainPID -p ExecStartPre | cut -c1-200
V; P '{"on":true}'; sleep 1; V; sleep 9; V
journalctl -u fpv-mediamtx -u fpv-bridge --since "-11s" --no-pager -o short-precise | cut -c8-210 | grep -v "RTSP\] \[" | tail -25
timeout 9 ffmpeg -hide_banner -nostats -rtsp_transport tcp -i rtsp://localhost:8554/cam -t 5 -c copy -f null - 2>&1 | grep -oE "[0-9]+x[0-9]+|frame= *[0-9]+|video:[0-9]+KiB" | tr '\n' ' '; echo
systemctl show fpv-mediamtx -p MainPID; P '{"on":false}'; sleep 4; V
