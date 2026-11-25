#timeout 60
for i in 1 2 3; do curl -s http://localhost:8080/api/rec | python3 -c "import sys,json;d=json.load(sys.stdin);print(json.dumps(d.get('cockpit')))"; sleep 4; done
grep -m1 VERSION /opt/fpv/fpvcfg.py
echo "[100%] done"
