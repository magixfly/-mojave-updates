#nobox
touch /tmp/claude_remote
sleep 240; touch /tmp/claude_remote
curl -s -X POST -H 'Content-Type: application/json' -d '{"check":1}' localhost:8080/api/update | head -c 300; echo
curl -s -X POST -H 'Content-Type: application/json' -d '{"install":1}' localhost:8080/api/update | head -c 300; echo
for i in $(seq 1 30); do sleep 5; v=$(curl -s -m 3 localhost:8080/api/state | python3 -c "import json,sys;d=json.load(sys.stdin);print(d.get('ver'),json.dumps({k:d.get('sys',{}).get(k) for k in ('uv','uv_ago','uv_n','thr')}))" 2>/dev/null); [ -n "$v" ] && case "$v" in 3.37*) echo "$v"; break;; esac; done
sleep 15; touch /tmp/claude_remote; curl -s localhost:8080/api/state | python3 -c "import json,sys;d=json.load(sys.stdin);print(d.get('ver'),{k:d.get('sys',{}).get(k) for k in ('uv','uv_ago','uv_n','thr')})"
