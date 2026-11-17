#nobox
H=192.168.178.175
curl -s -m 30 "http://$H/tpl/devicesettings.tpl.html" > outbox/176_dev.tpl.log; wc -c outbox/176_dev.tpl.log
for f in $(grep -oiE "(tpl|js|php)/[a-z0-9_./-]*(wifi|wlan|network|net)[a-z0-9_.-]*" outbox/176_dev.tpl.log | sort -u); do echo "== $f"; curl -s -m 20 "http://$H/$f" | head -c 4000 > "outbox/176_$(basename $f).log"; done
ls -la outbox/176_*
