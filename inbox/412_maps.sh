#nobox
curl -s --max-time 4 http://127.0.0.1:8080/api/state | python3 -c "import json,sys;d=json.load(sys.stdin);print('region',d.get('region'));print('dl',d.get('dl'),d.get('dlsrc'),'autopre',d.get('autopre'),'online',d.get('online'))"
grep -E "^(zentrale|areas|map_zmax|online|areas_cleaned)=" ~/Bodenstation/config.txt
grep -iE "areas|region" ~/Bodenstation/server.log 2>/dev/null | tail -8
du -sh ~/Bodenstation/tiles/* 2>/dev/null; df -h / | tail -1
