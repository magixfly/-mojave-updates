#timeout 60
for i in 1 2 3 4 5 6; do curl -s http://localhost:8080/api/rec | python3 -c "import sys,json; print(json.load(sys.stdin).get('cockpit'))"; sleep 2; done
grep -E "rpiCamera(Width|Height|FPS|Bitrate)" /etc/fpv/mediamtx.yml | head -4 | tr -s ' ' | tr '\n' ';'; echo
grep -n "rpiCamera" /etc/fpv/mediamtx.yml | tr -s ' ' | cut -c1-60 | tr '\n' ';'; echo
uptime | sed 's/.*load/load/'
