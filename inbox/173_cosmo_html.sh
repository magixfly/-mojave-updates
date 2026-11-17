#nobox
H=192.168.178.175
curl -s -m 40 -o /tmp/cs.html -w "code %{http_code} exit-time %{time_total}\n" "http://$H/"; wc -c /tmp/cs.html
grep -oiE "(action|href|src)=\"[^\"]*\"" /tmp/cs.html | grep -viE "icons/|\.png|\.css" | sort -u | head -40
grep -oiE "[a-z_/]*\.php[a-z_?=&]*" /tmp/cs.html | sort -u | head -40
grep -n -iE "wifi|wlan|ssid|country|wireless" /tmp/cs.html | cut -c1-220 | head -60
