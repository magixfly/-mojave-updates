#nobox
curl -s --max-time 6 http://192.168.178.209/api/status | python3 -c "import json,sys;d=json.load(sys.stdin);print({k:d.get(k) for k in ('ver','dlText','dlPct','liste','ls','lsText','lsQuelle','areas','upd','sd')})" 2>&1 | head -c 1500
echo; curl -s --max-time 6 http://192.168.178.209/api/status | head -c 1500
