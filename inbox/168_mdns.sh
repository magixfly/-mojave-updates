adb shell ping -c1 -W2 corepi.local 2>&1 | head -2
adb shell "toybox nc -w 2 corepi.local 8080 </dev/null && echo nc-local-ok || echo nc-local-fail"
journalctl --user -n 0 >/dev/null 2>&1; grep -c 'POST /api/box' ~/Bodenstation/server.log 2>/dev/null; tail -3 ~/Bodenstation/server.log 2>/dev/null | cut -c1-150
