# Ist der CosmoStreamer gerade erreichbar?
for h in cosmostreamer.local 192.168.178.175; do printf "%s: " $h; curl -s -m 3 http://$h/ | grep -io '<title>[^<]*' | head -1; echo; done
getent hosts cosmostreamer.local; ip neigh | grep -i "192.168.178" | head -20
