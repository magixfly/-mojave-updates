#timeout 60
ip -4 route show default
for a in 127.0.0.1:8081 192.168.100.1 192.168.100.33; do curl -s -m 6 -o /dev/null -w "$a http %{http_code} %{size_download} bytes\n" http://$a/; done
ip neigh show dev eth1 | head -4
echo "[100%] done"
