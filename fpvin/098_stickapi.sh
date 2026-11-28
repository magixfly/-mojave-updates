#timeout 90
G=$(ip -4 route show default dev eth1 | awk '{print $3; exit}'); echo "stick gateway: $G"
T=$(mktemp -d); cd $T
curl -s -m 8 http://$G/ -o index.html; echo "index: $(wc -c < index.html) bytes"
echo "--- title / scripts / links ---"
grep -oiE '<title>[^<]*|src="[^"]+"|href="[^"]+\.(html|htm|js)"' index.html | head -30
for s in $(grep -oiE 'src="[^"]+\.js[^"]*"' index.html | sed 's/src="//;s/"$//' | head -15); do
  s2=${s#/}; curl -s -m 8 "http://$G/$s2" -o "js_$(basename ${s2%%\?*})"; done
ls -la
echo "--- endpoints mentioned in page and scripts ---"
cat index.html js_* 2>/dev/null | grep -oE '["'"'"'][^"'"'"' ]*(goform|cgi|/api/|\.asp|\.json|xml|reqproc|ajax)[^"'"'"' ]*["'"'"']' | sort | uniq -c | sort -rn | head -50
echo "--- signal words ---"
cat index.html js_* 2>/dev/null | grep -oiE '.{0,40}(rsrp|rsrq|sinr|rssi|signal_strength|network_type|lte_band|cell_id|operator|plmn).{0,40}' | sort -u | head -40
echo "--- common API tries ---"
for u in "goform/goform_get_cmd_process?multi_data=1&cmd=signalbar,network_type,lte_rsrp,lte_rsrq,lte_snr,lte_rssi,network_provider,lte_band,cell_id" "api/device/signal" "api/monitoring/status" "reqproc/proc_get?cmd=signal" "cgi-bin/info.cgi" "xml_action.cgi?method=get&module=duster&file=status1" "status.json" "api/status"; do
  echo "== /$u"; curl -s -m 5 -H "Referer: http://$G/" "http://$G/$u" | head -c 400; echo; done
echo "[100%] done"
