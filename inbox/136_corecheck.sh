#screenshot
# Core-Anzeige prüfen
curl -s localhost:8080/api/state | python3 -c "import json,sys;d=json.load(sys.stdin);print('ver',d.get('ver'));print('core',d.get('core'));print('model',d.get('model'),'esp',d.get('esp'))"
curl -s localhost:8080/api/devices | python3 -c "import json,sys;d=json.load(sys.stdin).get('d',{});print('dev core',d.get('core'));print('dev tracker',d.get('tracker'))"
grep -E "^core|^me_gps" ~/Bodenstation/config.txt
tail -5 /tmp/sm.log 2>/dev/null; ip -br addr | grep wlan
