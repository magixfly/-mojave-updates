#nobox
cd ~/Bodenstation
grep -E "^(map_|vgps|test_|home|navi|phone)" config.txt
curl -s localhost:8080/api/state | python3 -c "import json,sys;d=json.load(sys.stdin);print({k:d.get(k) for k in (\"lat\",\"lon\",\"fix\",\"vgps\",\"src\",\"phone\",\"me\",\"hw\",\"ssid\")})"
curl -s localhost:8080/api/config | python3 -c "import json,sys;d=json.load(sys.stdin);print({k:v for k,v in d.items() if any(s in k for s in (\"map\",\"vgps\",\"test\",\"home\",\"lat\",\"lon\"))})"
iwgetid -r
