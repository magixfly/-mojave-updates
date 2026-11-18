#nobox
curl -s -m 20 http://192.168.178.159/js/player-pion.js > outbox/276_pion.js.log; wc -c outbox/276_pion.js.log; grep -n "getElementById\|remotevideo\|video_element\|ws://\|new WebSocket\|:80[0-9][0-9]" outbox/276_pion.js.log | head -20
