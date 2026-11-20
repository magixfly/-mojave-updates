#nobox
curl -s localhost:8080/api/state | python3 -c "
import json,sys;d=json.load(sys.stdin)
print({k:d.get(k) for k in ['ver','esp','espq','src','me','phone','vgps','sats','lat']})"
ls -la /dev/ttyACM* /dev/ttyUSB* 2>/dev/null
