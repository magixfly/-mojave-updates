#nobox
curl -s -X POST -H 'Content-Type: application/json' -d '{"toggle":1}' localhost:8080/api/boxcmd; echo
sleep 40
curl -s localhost:8080/api/state | python3 -c "import json,sys;print(json.load(sys.stdin)[\"box\"][\"txt\"])"
