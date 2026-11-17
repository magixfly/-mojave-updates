#nobox
H=192.168.178.175
curl -s -m 30 "http://$H/tpl/devicesettings.wifi.tpl.html" > outbox/178_wifi.tpl.log; wc -c outbox/178_wifi.tpl.log
for f in $(grep -oiE "(js|php|cgi-bin|tpl)/[a-z0-9_./-]+" outbox/178_wifi.tpl.log | sort -u); do echo "== $f"; curl -s -m 20 "http://$H/$f" > "outbox/178_$(basename $f).log"; done
