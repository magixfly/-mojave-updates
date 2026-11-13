#screenshot
# Kartendownload auf der Box stoppen (nur wenn er läuft)
st=$(curl -s -m 3 http://127.0.0.1:8080/api/state | python3 -c 'import sys,json;b=json.load(sys.stdin).get("box") or {};print(b.get("stop"), b.get("txt"))')
echo "vorher: $st"
case "$st" in True*|1*) echo "schon gestoppt";; *) curl -s -m 3 -X POST -H 'Content-Type: application/json' -d '{"toggle":1}' http://127.0.0.1:8080/api/boxcmd; echo; sleep 8;; esac
curl -s -m 3 http://127.0.0.1:8080/api/state | python3 -c 'import sys,json;b=json.load(sys.stdin).get("box") or {};print("nachher:", b.get("stop"), b.get("txt"))'
