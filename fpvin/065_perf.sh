#timeout 60
for i in 1 2 3 4 5; do curl -s http://localhost:8080/api/rec | python3 -c "import sys,json; d=json.load(sys.stdin); print('cockpit:', d.get('cockpit'))"; sleep 2; done
grep -E "rpiCamera(Width|Height|FPS|Bitrate|IDRPeriod)" /etc/fpv/mediamtx.yml | head -5 | tr -s ' ' | tr '\n' ';'; echo
uptime | sed 's/.*load/load/'; vcgencmd measure_temp; top -bn1 -o %CPU | sed -n 8,12p | awk '{print $9, $12}' | tr '\n' ';'; echo
journalctl -u fpv-mediamtx --since "-10min" --no-pager -o cat | grep -c "WebRTC.*created"
