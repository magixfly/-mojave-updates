#timeout 60
echo "boot: $(uptime -s)"
echo "services: $(systemctl is-active fpv-bridge fpv-mediamtx fpv-stickpage fpv-remote tailscaled | tr '\n' ' ')"
echo "radio wifi: $(nmcli radio wifi)"
nmcli -t -f NAME,AUTOCONNECT-PRIORITY,ACTIVE connection show | grep -vE "^lo|tailscale"
ip -4 route show default
echo "net: $(curl -s -m 5 http://localhost:8080/api/net)"
echo "stick page: $(curl -s -m 8 -o /dev/null -w '%{http_code}' http://127.0.0.1:8081/)"
echo "video: $(curl -s -m 5 -o /dev/null -w '%{http_code}' http://127.0.0.1:8889/cam/)"
echo "ping: $(ping -c 3 -q 1.1.1.1 | tail -1)"
journalctl -b -p err --no-pager -n 8 | cut -c1-150
echo "[100%] done"
