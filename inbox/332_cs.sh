#nobox
curl -s -m 5 http://192.168.178.175/ | grep -oiE "(resolution|bitrate|720|1080|480|quality|fps)[^<]{0,80}" | sort -u | head -30
for p in settings settings.html config api/settings api/config api/status status; do echo "== $p $(curl -s -m 3 -o /tmp/cs_$p -w %{http_code} http://192.168.178.175/$p)"; done
grep -oiE "(resolution|bitrate|720p|1080p|480p|scale|width|height)[^<]{0,60}" /tmp/cs_* 2>/dev/null | sort -u | head -20
curl -s -m 5 http://192.168.178.175/ | grep -oE 'src="[^"]+\.js"|href="[^"]+"' | head -20
