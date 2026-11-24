#nobox
N=http://192.168.178.209
curl -s --max-time 6 -X POST --data check $N/api/upd; echo; sleep 25
curl -s --max-time 6 $N/api/status | python3 -c "import json,sys;d=json.load(sys.stdin);print(d['ver'],d.get('upd'))" | cut -c1-200
curl -s --max-time 6 -X POST --data install $N/api/upd; echo
for i in 1 2 3 4 5 6 7 8 9 10 11 12; do sleep 15; r=$(curl -s --max-time 5 $N/api/status | python3 -c "import json,sys;d=json.load(sys.stdin);u=d.get('upd',{});print(d['ver'],u.get('z'),u.get('pct'),d.get('lsText',''))" 2>/dev/null); echo "$i $r"; done
