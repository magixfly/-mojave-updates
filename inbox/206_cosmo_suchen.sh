for i in $(seq 2 254); do timeout 0.4 ping -c1 -W1 192.168.178.$i >/dev/null 2>&1; done
ip neigh | grep -i "dc:a6:32:09:df:0d\|\.159 \|\.175 "
for ip in 192.168.178.159 192.168.178.175; do echo "$ip: $(curl -s -m 3 http://$ip/ | grep -io '<title>[^<]*' | head -1)"; done
