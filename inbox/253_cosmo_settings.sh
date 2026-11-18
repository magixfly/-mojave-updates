for p in / /settings /settings.html /video /config /api/settings /api/config; do echo "== $p $(curl -s -m 4 -o /tmp/c.html -w '%{http_code} %{size_download}' http://192.168.178.159$p)"; grep -o -i '[^<>]\{0,60\}\(transcod\|resize\|resolution\|720\)[^<>]\{0,60\}' /tmp/c.html | head -6; done
grep -o 'href="[^"]*"' /tmp/c.html | sort -u | head -30
curl -s -m 4 http://192.168.178.159/ | grep -o 'href="[^"#]*"' | sort -u | head -30
