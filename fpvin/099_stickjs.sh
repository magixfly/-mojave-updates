#timeout 90
G=$(ip -4 route show default dev eth1 | awk '{print $3; exit}')
T=$(mktemp -d); cd $T
for f in js/base/ajax_calls.js js/panel/dashboard.js js/base/utils.js js/panel/internet/internet_connection.js; do curl -s -m 8 "http://$G/$f" -o "$(basename $f)"; done
echo "=== ajax_calls.js: login / digest / authorization ==="
grep -nE "login|Digest|Authorization|realm|nonce|md5|hex_md5|qop|cnonce|AuthQop|GetAuth|getAuth" ajax_calls.js | cut -c1-220 | head -60
echo "=== dashboard.js: files and fields ==="
grep -noE "file=[a-z_0-9]+|'[a-z_0-9]*(rssi|rsrp|rsrq|sinr|snr|band|cell|network|operator|plmn|signal|sys_mode|rat|carrier|roam)[a-z_0-9]*'|\"[a-z_0-9]*(rssi|rsrp|rsrq|sinr|snr|band|cell|network|operator|plmn|signal|sys_mode|rat|carrier|roam)[a-z_0-9]*\"" dashboard.js | sort -t: -k2 -u | head -60
echo "=== utils.js: signal/network helpers ==="
grep -nE "rssi|rsrp|sinr|signal|network_type|sys_mode" utils.js | cut -c1-200 | head -30
echo "=== xml files that answer without login ==="
for f in status1 wan ui_status statistics device_management wan_status lte_status; do
  echo "$f: $(curl -s -m 5 "http://$G/xml_action.cgi?method=get&module=duster&file=$f" | head -c 200)"; done
echo "=== login.cgi headers ==="
curl -s -m 5 -D - -o /dev/null "http://$G/login.cgi" | head -12
echo "[100%] done"
