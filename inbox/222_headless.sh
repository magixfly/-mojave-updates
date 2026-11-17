timeout 60 chromium --headless=new --disable-gpu --no-sandbox --user-data-dir=/tmp/hl --window-size=1280,720 --virtual-time-budget=9000 --screenshot=outbox/222_hl.png http://127.0.0.1:8080/ 2>&1 | tail -3
timeout 60 chromium --headless=new --disable-gpu --no-sandbox --user-data-dir=/tmp/hl --virtual-time-budget=9000 --dump-dom http://127.0.0.1:8080/ 2>/dev/null | grep -o '<html[^>]*>' | head -1
