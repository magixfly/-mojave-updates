#timeout 60
G=$(ip -4 route show default dev eth1 | awk '{print $3; exit}')
T=$(mktemp -d); cd $T
curl -s -m 8 "http://$G/" -o index.html
for s in $(grep -oE 'src="js/panel/[^"]+\.js"' index.html | sed 's/src="//;s/"$//'); do curl -s -m 8 "http://$G/$s" -o "$(echo $s | tr / _)"; done
echo "=== files mentioning rsrp / sinr / Engineering ==="
grep -lE "rsrp|sinr|Engineering_mode" js_panel_* 
echo "=== lines ==="
grep -nE "rsrp|sinr|rsrq|Engineering_mode|query_time_interval|cellid|bandset|file=" $(grep -lE "rsrp|sinr|Engineering_mode" js_panel_*) | cut -c1-230 | head -60
echo "=== signal bar on dashboard (rssi use) ==="
grep -nE "rssi" js_panel_dashboard.js js_panel_*.js | cut -c1-200 | head -20
echo "[100%] done"
