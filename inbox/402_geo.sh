#nobox
cd /tmp
W="14.2861,48.3064;14.2856,48.2253;15.6372,48.1786;16.2192,48.2063;16.4198,48.2340;16.3585,48.1395;16.2346,47.8155;15.9389,47.6756"
curl -s --max-time 40 "https://router.project-osrm.org/route/v1/driving/$W?overview=full&geometries=geojson" -o r.json; ls -la r.json
python3 - <<'PY'
import json,math
try:
    d=json.load(open('/tmp/r.json'));c=d['routes'][0]['geometry']['coordinates'];print('pts',len(c),'km',round(d['routes'][0]['distance']/1000))
    out=[c[0]]
    for p in c[1:]:
        q=out[-1]
        if math.hypot((p[0]-q[0])*75000,(p[1]-q[1])*111000)>400: out.append(p)
    out.append(c[-1])
    print('ROUTE='+json.dumps([[round(p[1],5),round(p[0],5)] for p in out]))
except Exception as e: print('osrm err',e)
PY
N=$(curl -s --max-time 5 http://127.0.0.1:8080/api/devices | python3 -c "import json,sys;d=json.load(sys.stdin)['d'];print(json.dumps({k:v for k,v in d.items() if k!='cosmo'}))"); echo "DEV $N"
for h in navi.local corenav.local $(echo "$N" | grep -o '"ip": "[0-9.]*"' | grep -o '[0-9.]*[0-9]'); do
  r=$(curl -s --max-time 4 http://$h/api/eigene); [ -n "$r" ] && { echo "NAVI $h EIGENE $r"; echo "NAVI $h GEB $(curl -s --max-time 6 http://$h/api/gebiete | head -c 3000)"; echo "NAVI $h STATUS $(curl -s --max-time 4 http://$h/api/status | head -c 600)"; break; }
done
