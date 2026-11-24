#nobox
curl -s --max-time 4 http://127.0.0.1:8080/api/state | python3 -c "import json,sys;d=json.load(sys.stdin);print('hw',d.get('hw'));print('src',d.get('src'),'dev',d.get('dev'))"
ls -la /dev/ttyACM* /dev/ttyUSB* 2>&1
lsusb 2>&1 | grep -iv hub
tail -5 ~/Bodenstation/server.log 2>/dev/null
