#nobox
for i in $(seq 1 6); do curl -s -X POST -H "Content-Type: application/json" -d "{\"check\":1}" http://127.0.0.1:8080/api/update >/dev/null; sleep 10; curl -s -X POST -H "Content-Type: application/json" -d "{\"install\":1}" http://127.0.0.1:8080/api/update >/dev/null; for k in $(seq 1 20); do sleep 3; curl -s --max-time 2 http://127.0.0.1:8080/api/state | head -c 30 | grep -q "\"3.31\"" && { echo "3.31 läuft"; break 2; }; done; sleep 20; done
cd /home/user1/Bodenstation && pkill -f "python3.*server.py" ; sleep 1
grep -q "^starts_hide=" config.txt && sed -i 's/^starts_hide=.*/starts_hide=48.188118,15.608036/' config.txt || echo "starts_hide=48.188118,15.608036" >> config.txt
