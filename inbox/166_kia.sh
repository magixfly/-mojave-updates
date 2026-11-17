#nobox
for i in 1 2 3 4 5; do curl -s -m 3 http://127.0.0.1:8080/api/state | python3 -c "import sys,json;b=json.load(sys.stdin).get('box');print('box:', (b or {}).get('txt'), (b or {}).get('ver'))"; sleep 3; done
ps aux | grep -E 'chromium|firefox|kiosk' | grep -v grep | grep -oE 'http[^ ]*' | head -3
export DISPLAY=:0 XDG_RUNTIME_DIR=/run/user/$(id -u); (grim /tmp/pi.png 2>/dev/null || scrot /tmp/pi.png 2>/dev/null) && ls -la /tmp/pi.png && cp /tmp/pi.png outbox/${0##*/}.pi.png 2>/dev/null; ls outbox | tail -1
