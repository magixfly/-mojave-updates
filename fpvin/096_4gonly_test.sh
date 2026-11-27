#timeout 180
A=http://localhost:8080/api/net
back() { curl -s -m 5 -X POST -H "X-FPV: 1" -H "Content-Type: application/json" -d '{"wifi": true}' $A >/dev/null; nmcli radio wifi on; }
trap back EXIT
st() { echo "  routes: $(ip -4 route show default | awk '{print $5"/"$NF}' | tr '\n' ' ')"; echo "  net: $(curl -s -m 5 $A)"; }
echo "--- before ---"; st
echo "--- switch to 4G only ---"
curl -s -m 10 -X POST -H "X-FPV: 1" -H "Content-Type: application/json" -d '{"wifi": false}' $A; echo
sleep 20; st
echo "  radio: $(nmcli radio wifi)"
echo "  ping 1.1.1.1: $(ping -c 5 -q 1.1.1.1 | tail -1)"
echo "  github: $(curl -s -m 10 -o /dev/null -w '%{http_code} %{time_total}s' https://raw.githubusercontent.com/magixfly/-mojave-updates/carlin/README.md)"
echo "  tailscale: $(tailscale status --peers=false 2>/dev/null | head -1)"
echo "  tailscale netcheck: $(timeout 20 tailscale netcheck 2>/dev/null | grep -E 'Nearest DERP|UDP' | tr '\n' ' ')"
echo "  services: $(systemctl is-active fpv-bridge fpv-mediamtx fpv-stickpage | tr '\n' ' ')"
echo "--- back to Auto (Wi-Fi first) ---"
curl -s -m 10 -X POST -H "X-FPV: 1" -H "Content-Type: application/json" -d '{"wifi": true}' $A; echo
for i in $(seq 1 30); do sleep 2; ip -4 route show default | grep -q wlan0 && break; done
echo "  Wi-Fi back after about $((i*2)) s"; st
echo "  ping 1.1.1.1: $(ping -c 3 -q 1.1.1.1 | tail -1)"
echo "[100%] done"
