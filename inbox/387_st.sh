#nobox
curl -s localhost:8080/api/state | python3 -c "import json,sys;d=json.load(sys.stdin);print(\"box=\",d.get(\"box\"))"
DISPLAY=:0 grim /tmp/s.png 2>/dev/null || DISPLAY=:0 scrot -o /tmp/s.png 2>/dev/null; ls -la /tmp/s.png 2>&1
