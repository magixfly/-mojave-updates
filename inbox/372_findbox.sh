#nobox
touch /tmp/claude_remote
echo "Pi: $(hostname -I)"; nmcli -t -f ACTIVE,SSID dev wifi | grep '^yes'
for i in $(seq 1 254); do (ping -c1 -W1 192.168.178.$i >/dev/null 2>&1 &); done; sleep 4
echo "== Box-MAC b0:5a:44:75:3e:33"; ip neigh | grep -i "b0:5a:44:75:3e:33" || echo "nicht im Heimnetz"
for ip in $(ip neigh | awk '/192.168.178/ && /lladdr/ {print $1}'); do timeout 2 bash -c "echo > /dev/tcp/$ip/8090" 2>/dev/null && echo "Port 8090 offen: $ip"; done
