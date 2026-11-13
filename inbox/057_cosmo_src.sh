# Quelltext der CosmoStreamer-Seite holen (für den FPV-Player in der App)
mkdir -p outbox/cosmo; cd outbox/cosmo
curl -s -m 5 http://192.168.178.175/ -o index.html; ls -la index.html
for u in $(grep -oE '(src|href)="[^"]+\.(js|css)[^"]*"' index.html | sed -E 's/.*="([^"]+)"/\1/' | sort -u); do
  f=$(echo "$u" | sed 's#^/##; s#[/?]#_#g'); case "$u" in http*) url="$u";; /*) url="http://192.168.178.175$u";; *) url="http://192.168.178.175/$u";; esac
  curl -s -m 5 "$url" -o "$f"; echo "$url -> $f $(stat -c %s "$f")"
done
