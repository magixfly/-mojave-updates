#nobox
curl -s localhost:8080/api/rides | python3 -c "
import json,sys
for r in json.load(sys.stdin)['rides']:
    print(r['name'],r.get('lat0'),r.get('lon0'),'km',r['km'],'vmax',r['vmax'],'dur',r['dur'],(r.get('veh') or {}).get('name'),r.get('driver'))"
