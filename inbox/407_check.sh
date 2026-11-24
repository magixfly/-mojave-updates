#nobox
Z=$(grep '^zentrale=' ~/Bodenstation/config.txt | cut -d= -f2 | awk '{print $1}')
curl -s --max-time 5 $Z/api/ping; echo
curl -s --max-time 10 $Z/gebiete.json | python3 -c "import json,sys;d=json.load(sys.stdin);print('ver',d['ver']);[print(' ',a['id'],a['name'],a.get('zmax'),len(a.get('pts',[]))) for a in d['areas']]"
