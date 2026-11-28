#timeout 40
echo "lte: $(curl -s -m 5 http://localhost:8080/api/lte | sed 's/"user": "[^"]*"/"user": "*"/')"
echo "tags: $(curl -s -m 5 http://localhost:8080/api/lte/tags)"
journalctl -u fpv-bridge --no-pager | grep "\[lte\]" | tail -4
echo "[100%] done"
