#nobox
curl -s -m 5 http://192.168.178.175/ > /tmp/cs.html
grep -oE ".{200}resolution\" style.{200}" /tmp/cs.html | head -2
grep -oE "<select[^>]*>.{0,300}" /tmp/cs.html | head -12 | cut -c1-300
for f in $(grep -oE 'src="js/[^"?]+' /tmp/cs.html | sed 's/src="//'); do curl -s -m 5 http://192.168.178.175/$f > /tmp/csj; echo "== $f $(wc -c </tmp/csj)"; grep -oiE ".{60}(resolution|scale_|downscale|720|480).{60}" /tmp/csj | head -6; done
