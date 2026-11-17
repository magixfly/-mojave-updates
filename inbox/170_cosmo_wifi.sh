#nobox
# CosmoStreamer im Heimnetz finden und WLAN-Status lesen
for h in cosmostreamer.local 192.168.178.175; do echo "--- $h"; curl -s -m 4 -o /tmp/cs.html -w "%{http_code} %{remote_ip}\n" "http://$h/"; done
grep -io '<title>[^<]*' /tmp/cs.html
echo "--- Links"; grep -oiE "(href|src|url|fetch\(|get\(|post\()[=( ]*['\"][^'\"]*['\"]" /tmp/cs.html | sort -u | head -60
echo "--- WLAN-Wörter"; grep -oiE ".{0,80}(wifi|wlan|ssid|wireless|5ghz|country).{0,80}" /tmp/cs.html | head -40
echo "--- Raspberry-Geräte im Netz"; ping -c1 -b -W1 192.168.178.255 >/dev/null 2>&1; for i in $(seq 1 254); do ping -c1 -W1 192.168.178.$i >/dev/null 2>&1 & done; wait; ip neigh | grep -iE "dc:a6:32|e4:5f:01|b8:27:eb|d8:3a:dd|2c:cf:67|28:cd:c1" 
