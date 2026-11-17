#nobox
H=192.168.178.175
for f in tabs data screen; do curl -s -m 30 "http://$H/js/$f.js" > outbox/175_$f.js.log; done
wc -c outbox/175_*.js.log
