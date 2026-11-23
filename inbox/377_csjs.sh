#nobox
mkdir -p outbox/cs; for f in js/screen.js js/player-webrtc.js js/player-pion.js js/player-websockets.js; do curl -s -m 5 http://192.168.178.159/$f > outbox/cs/$(basename $f); done; ls -la outbox/cs
