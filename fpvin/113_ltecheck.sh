#timeout 120
journalctl -u fpv-bridge --no-pager --since "-6h" | grep "\[lte\]" | tail -12
sleep 45
echo "now: $(curl -s -m 5 http://localhost:8080/api/lte | python3 -c 'import sys,json;d=json.load(sys.stdin);print(d.get("state"),d.get("dbm"),d.get("band"),d.get("login"))')"
ls -la /etc/fpv/stick-login
echo "[100%] done"
