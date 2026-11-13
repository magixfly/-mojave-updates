#nobox
# Tracker 2.0.50 (WLAN-Stromsparmodus aus) installieren, dann Stromsparmodus prüfen
for i in 1 2 3 4 5 6; do r=$(curl -s -m 20 -X POST -H 'Content-Type: application/json' -d '{"check":1}' http://127.0.0.1:8080/api/update); echo "$r" | grep -q '"2.0.50"' && break; sleep 50; done
curl -s -m 30 -X POST -H 'Content-Type: application/json' -d '{"install":1}' http://127.0.0.1:8080/api/update | head -c 200; echo
sleep 40; curl -s -m 5 http://127.0.0.1:8080/api/state | grep -o '"ver": *"[^"]*"' | head -1
for c in XVII CoreTracker; do echo "$c: powersave=$(nmcli -g 802-11-wireless.powersave con show "$c")"; done
