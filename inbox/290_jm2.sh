#nobox
curl -s -m 10 http://192.168.178.159/js/player-websockets.js > outbox/290_ws.js.log; wc -c outbox/290_ws.js.log
sleep 20; grep fpvstat /tmp/tracker_dbg.txt | tail -1 | cut -c1-300
