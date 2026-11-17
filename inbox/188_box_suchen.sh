echo "--- Tracker meldet Box:"; curl -s --max-time 3 http://127.0.0.1:8080/api/devices | python3 -c "import sys,json;d=json.load(sys.stdin).get('d',{});print(d.get('box'))" 2>&1
echo "--- ip neigh:"; ip neigh | grep -v FAILED
echo "--- Port 5555 im Netz:"; for i in $(seq 2 254); do (timeout 1 bash -c "echo >/dev/tcp/192.168.178.$i/5555" 2>/dev/null && echo "offen: 192.168.178.$i") & done; wait
for ip in $(ip neigh | awk '{print $1}' | grep '^192\.168\.178\.'); do timeout 3 adb connect $ip:5555 2>&1 | grep -i connected; done
adb devices -l
