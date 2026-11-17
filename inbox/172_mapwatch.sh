# Karten-Download der Box 2 min beobachten
for i in $(seq 1 24); do curl -s -m 3 http://127.0.0.1:8080/api/state | python3 -c "import sys,json,time;b=json.load(sys.stdin).get('box') or {};print(time.strftime('%T'),b.get('txt'),'dl',b.get('dl'),b.get('net'))"; sleep 5; done
adb logcat -d -t 3000 | grep -iE 'tile|basemap|SocketTimeout|UnknownHost' | tail -5 | cut -c1-160
