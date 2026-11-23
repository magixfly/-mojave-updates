#nobox
# 23.11.: CosmoStreamer erneut suchen
touch /tmp/claude_remote
echo "Pi: $(hostname -I)"
getent hosts cosmostreamer.local || echo "cosmostreamer.local: kein mDNS"
for i in $(seq 1 254); do (ping -c1 -W1 192.168.178.$i >/dev/null 2>&1 &) ; done; sleep 4
echo "== MAC"; ip neigh | grep -i "dc:a6:32" || echo "keine Raspberry-MAC dc:a6:32 gefunden"
echo "== Titel-Suche"
for ip in $(ip neigh | awk '/192.168.178/ && /lladdr/ {print $1}'); do t=$(curl -s -m 2 http://$ip/ | grep -o -i '<title>[^<]*' | head -1); echo "$ip $t"; done | grep -i cosmo || echo "keine Cosmostreamer-Seite"
echo "== Geräte im Netz: $(ip neigh | grep -c lladdr)"
curl -s localhost:8080/api/devices | python3 -c "import json,sys;print((json.load(sys.stdin).get('d') or {}).get('cosmo'))"
