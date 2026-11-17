#nobox
python3 tools/cosmows.py 192.168.178.175 '{"cmd":"config_request","param":"wifi"}' 2>&1 | grep -oE '"(sys_country|wifi_ssid|wifi_ip)":"[^"]*"|"cmd":"ifaces"[^}]*' | sort -u
