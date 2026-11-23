#nobox
ip -4 addr show wlan0 | grep inet; ip route | head -2; iwgetid -r
pre=$(ip -4 route | awk '/^default/{print $3}' | cut -d. -f1-3)
for i in $(seq 1 254); do ( timeout 0.6 bash -c "</dev/tcp/$pre.$i/80" 2>/dev/null && echo "$pre.$i:80" ) & done; wait
for h in $(for i in $(seq 1 254); do ( timeout 0.6 bash -c "</dev/tcp/$pre.$i/80" 2>/dev/null && echo "$pre.$i" ) & done; wait); do t=$(curl -s -m 2 http://$h/ | grep -o -i -m1 "cosmo[a-z]*" | head -1); echo "$h $t"; done
curl -s localhost:8080/api/state | python3 -c "import json,sys;d=json.load(sys.stdin);print('cosmo',d.get('cosmo'),d.get('box'))"
