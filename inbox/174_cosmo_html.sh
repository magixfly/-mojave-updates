#nobox
H=192.168.178.175
curl -s -m 40 "http://$H/" | tee outbox/174_cosmo.html.log | wc -c
