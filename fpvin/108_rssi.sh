#timeout 60
G=$(ip -4 route show default dev eth1 | awk '{print $3; exit}')
curl -s -m 8 "http://$G/js/panel/dashboard.js" | sed -n 196,262p | cut -c1-160
echo "=== engineering settings in wan.xml (names only above) ==="
for i in 1 2 3 4 5 6; do echo "$(date +%T) $(curl -s -m 5 http://localhost:8080/api/lte | python3 -c 'import sys,json;d=json.load(sys.stdin);r=d.get("raw",{});print(d.get("state"),{k:r.get(k) for k in ("rssi","rsrp","sinr","sys_mode","sys_submode","cellid","network_type")})')"; sleep 4; done
echo "[100%] done"
