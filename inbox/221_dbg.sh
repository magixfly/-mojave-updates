ps -eo args | grep -m2 "chromium.*kiosk\|chromium-browser\|chromium " | cut -c1-400
curl -s -m 3 http://127.0.0.1:9222/json 2>/dev/null | head -c 600
