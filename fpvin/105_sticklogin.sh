#timeout 60
G=$(ip -4 route show default dev eth1 | awk '{print $3; exit}'); echo "stick: $G"
T=$(mktemp -d); cd $T
for f in js/base/utils.js js/base/ajax_calls.js index.html js/base/layout_manager.js; do curl -s -m 8 "http://$G/$f" -o "$(basename $f)"; done
echo "=== utils.js 1-132 ==="; sed -n 1,132p utils.js
echo "=== ajax_calls.js authentication / getAuthType 530-600 ==="; sed -n 530,600p ajax_calls.js
echo "=== index.html: login form and calls ==="; grep -nE "doLogin|login|passwd|password|base64|encode" index.html | cut -c1-220 | head -40
grep -nE "doLogin|base64|Base64|encode\(" layout_manager.js ajax_calls.js | cut -c1-200 | head -20
echo "=== lte journal ==="; journalctl -u fpv-bridge --no-pager | grep "\[lte\]" | tail -10
echo "[100%] done"
