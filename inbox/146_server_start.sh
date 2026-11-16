# Nur den Server starten (Kiosk läuft noch und hält die Start-Sperre von start.sh)
export XDG_RUNTIME_DIR=/run/user/$(id -u)
cd ~/Bodenstation
pgrep -f "python3 .*Bodenstation/server.py" >/dev/null && echo "server läuft schon" || systemd-run --user --collect -p KillMode=process --working-directory=$HOME/Bodenstation bash -c "exec python3 $HOME/Bodenstation/server.py > $HOME/Bodenstation/server.log 2>&1"
sleep 15
pgrep -af "Bodenstation/server.py" | head -2
curl -s localhost:8080/api/state | python3 -c "import json,sys;d=json.load(sys.stdin);print('ver',d.get('ver'),'age',d.get('age'),'esp',d.get('esp'),'core via',(d.get('core') or {}).get('via'))"
