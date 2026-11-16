#!/bin/bash
#nobox
echo "--- Nachbarn"; ip neigh | grep -v FAILED
echo "--- Suche CosmoStreamer im Netz"
net=$(ip -4 addr show wlan0 | grep -o 'inet [0-9.]*' | cut -d' ' -f2 | cut -d. -f1-3)
for h in cosmostreamer.local $(seq -f "$net.%g" 2 254); do
  t=$(curl -s -m 1 "http://$h/" 2>/dev/null | grep -io '<title>[^<]*' | head -1)
  case "$t" in *[Cc]osmo*) echo "GEFUNDEN: $h $t";; esac
done 2>/dev/null &
wait
echo "--- Tracker-Liste"; curl -s -m 5 localhost:8080/api/devices | grep -o '"cosmo": {[^}]*}'
