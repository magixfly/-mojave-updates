#nobox
Z=$(grep '^zentrale=' ~/Bodenstation/config.txt | cut -d= -f2 | awk '{print $1}')
curl -s --max-time 10 $Z/gebiete.json > /tmp/g.json
python3 - <<'PY'
import json
d=json.load(open('/tmp/g.json'))
have={a['id'] for a in d['areas']}
for a in [{"id":"navi-perchtoldsdorf","name":"Perchtoldsdorfer Heide","type":"circle","lat":48.125424,"lon":16.248121,"r":1000,"zmax":18,"src":"navi"},
          {"id":"navi-amstetten","name":"Amstetten","type":"circle","lat":48.120326,"lon":14.875242,"r":5000,"zmax":18,"src":"navi"}]:
    if a['id'] not in have: d['areas'].append(a)
json.dump(d,open('/tmp/g2.json','w'))
PY
curl -s --max-time 10 -X POST --data-binary @/tmp/g2.json $Z/api/gebiete; echo
curl -s --max-time 5 $Z/api/ping; echo
