# Navi direkt prüfen
ip neigh | head -12
for h in 172.20.10.5 172.20.10.6; do echo "== $h"; curl -s -m 3 http://$h/api/status | head -c 400; echo; done
