# Core-Funk (ESP-NOW-Rundruf) am Tracker abschalten: ESP sucht den Core nicht mehr auf anderen Kanälen (keine Empfangslücken),
# Tracker holt Core-Werte nur noch per WLAN (core_live). Navi-Funk vom Core bleibt unberührt.
curl -s -X POST -H 'Content-Type: application/json' -d '{"k":"core_radio","v":"0"}' localhost:8080/api/cfgset; echo
pkill -f server.py; sleep 2
python3 - <<'PY'
import serial,time
s=serial.Serial('/dev/ttyACM0',115200,timeout=0.3);time.sleep(0.5);s.read(99999)
s.write(b'set core=0\nset core_scan=0\nsave\n');time.sleep(1.5)
print(bytes(b for b in s.read(99999) if 32<=b<127 or b==10).decode().strip()[-200:])
s.write(b'reboot\n');time.sleep(0.5)
PY
sleep 6
python3 - <<'PY'
import serial,time
s=serial.Serial('/dev/ttyACM0',115200,timeout=0.3);time.sleep(1);s.read(99999);s.write(b'status\n');time.sleep(1.2)
print('\n'.join(l for l in bytes(b for b in s.read(99999) if 32<=b<127 or b==10).decode().splitlines() if l.startswith('#')))
PY
systemd-run --user --collect --setenv=XDG_SESSION_TYPE=wayland --setenv=DISPLAY=:0 --setenv=WAYLAND_DISPLAY=wayland-0 --setenv=XDG_RUNTIME_DIR=/run/user/1000 --working-directory=$HOME/Bodenstation bash ./start.sh
sleep 25
curl -s localhost:8080/api/state | python3 -c "import json,sys;d=json.load(sys.stdin);print('ver',d.get('ver'),'esp',d.get('esp'),'core via',(d.get('core') or {}).get('via'))"
