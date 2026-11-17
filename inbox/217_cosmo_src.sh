mkdir -p outbox/cosmo; curl -s -m 5 http://192.168.178.159/ -o outbox/cosmo/index.html
grep -o 'src="[^"]*"' outbox/cosmo/index.html | head -20
grep -n -i "8088\|janus\|hostname\|location\.\|ws://\|jmuxer" outbox/cosmo/index.html | cut -c1-200 | head -30
for s in $(grep -o 'src="[^"]*\.js[^"]*"' outbox/cosmo/index.html | sed 's/src="//;s/"//' | grep -v '^http' | head -8); do f=$(basename "$s" | cut -d? -f1); curl -s -m 5 "http://192.168.178.159/${s#/}" -o "outbox/cosmo/$f"; echo "$s $(wc -c < outbox/cosmo/$f)"; done
