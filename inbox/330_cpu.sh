#nobox
top -b -n 2 -d 3 -o %CPU | awk '/^top -/{n++} n==2' | head -22 | cut -c1-140
echo; ps -eo pid,pcpu,etime,args --sort=-pcpu | head -8 | cut -c1-200
echo; vcgencmd get_throttled; vcgencmd measure_temp; uptime
echo; curl -s localhost:8080/api/state | python3 -c "import json,sys;d=json.load(sys.stdin);print({k:d.get(k) for k in ['ver','fpv','box','cpu','ram','temp','thr']})" 2>/dev/null
