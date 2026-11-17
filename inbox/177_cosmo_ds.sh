#nobox
H=192.168.178.175
curl -s -m 30 "http://$H/js/devicesettings.js" > outbox/177_ds.js.log; wc -c outbox/177_ds.js.log
