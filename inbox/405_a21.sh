#nobox
Z=$(grep '^zentrale=' ~/Bodenstation/config.txt | cut -d= -f2 | awk '{print $1}')
curl -s --max-time 10 $Z/gebiete.json > /tmp/g.json
python3 - <<'PY'
import json
d=json.load(open('/tmp/g.json'))
via=[[48.1525,15.9180],[48.1160,15.9920],[48.0560,16.0800],[48.0700,16.1950],[48.1090,16.3080]]
if not any(a['id']=='a21' for a in d['areas']):
    d['areas'].append({"id":"a21","name":"A21 Steinhaeusl - Alland - Voesendorf","type":"route","w":2000,"zmax":16,"src":"user","via":via,"pts":via})
json.dump(d,open('/tmp/g2.json','w'))
print('ver',d['ver'],[a['name'] for a in d['areas']])
PY
curl -s --max-time 10 -X POST --data-binary @/tmp/g2.json $Z/api/gebiete; echo
sleep 45
curl -s --max-time 10 $Z/gebiete.json | python3 -c "import json,sys;d=json.load(sys.stdin);a=[x for x in d['areas'] if x['id']=='a21'][0];print('ver',d['ver'],'a21 pts',len(a['pts']),a['pts'][:3],a['pts'][-2:])"
