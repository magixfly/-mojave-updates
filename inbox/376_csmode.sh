#nobox
curl -s -m 5 http://192.168.178.159/ > /tmp/cs.html; wc -c /tmp/cs.html
grep -o -E "video_player_mode[^;]{0,160}" /tmp/cs.html | head -8
grep -o -E "<option[^>]*>[^<]{0,40}" /tmp/cs.html | head -20
for f in $(grep -oE 'src="js/[^"?]+' /tmp/cs.html | sed 's/src="//'); do curl -s -m 5 http://192.168.178.159/$f > /tmp/csj; n=$(grep -c "video_player_mode\|playoutDelay\|jitterBuffer" /tmp/csj); [ "$n" != 0 ] && { echo "== $f"; grep -o -E ".{80}(video_player_mode|playoutDelay|jitterBuffer).{120}" /tmp/csj | head -6; }; done
