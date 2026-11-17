#nobox
python3 tools/cosmows.py 192.168.178.175 '{"cmd":"reboot"}' 2>&1 | head -3
for i in $(seq 1 16); do sleep 10; curl -s -m 3 -o /dev/null http://192.168.178.175/ && { echo "wieder da nach $((i*10)) s"; break; }; done
sleep 20
python3 tools/cosmows.py 192.168.178.175 '{"cmd":"config_request","param":"wifi"}' 2>&1 | grep -oE '"(sys_country|wifi_ssid|wifi_ip)":"[^"]*"|"cmd":"ifaces"[^}]*' | sort -u
