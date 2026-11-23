#nobox
# 23.11.: CosmoStreamer im Heimnetz suchen
touch /tmp/claude_remote
echo "Pi: $(hostname -I) WLAN: $(iwgetid -r)"
echo "== Name"; getent hosts cosmostreamer.local || echo "cosmostreamer.local: kein mDNS"
echo "== bekannte IP 192.168.178.175"; ping -c1 -W2 192.168.178.175 >/dev/null && echo "ping ok" || echo "ping fehlgeschlagen"
curl -s -m 4 http://192.168.178.175/ | grep -o -i '<title>[^<]*' | head -1
echo "== MAC dc:a6:32:09:df:0d im Netz?"; for i in $(seq 1 254); do (ping -c1 -W1 192.168.178.$i >/dev/null 2>&1 &) ; done; sleep 3; ip neigh | grep -i "dc:a6:32:09:df:0d" || echo "MAC nicht gefunden"
echo "== Seiten mit Titel Cosmostreamer (Port 80)"
for ip in $(ip neigh | awk '/192.168.178/ && /lladdr/ {print $1}'); do t=$(curl -s -m 2 http://$ip/ | grep -o -i '<title>cosmo[^<]*' | head -1); [ -n "$t" ] && echo "$ip $t"; done
echo "== Tracker-Geräteliste"; curl -s 'localhost:8080/api/devices?new=1' >/dev/null; sleep 20; curl -s localhost:8080/api/devices | python3 -c "import json,sys;d=(json.load(sys.stdin).get('d') or {}).get('cosmo');print(d)"
