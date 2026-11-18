curl -s -m 5 http://127.0.0.1:8080/api/devices | python3 -c "import sys,json;d=json.load(sys.stdin).get('d',{});print('cosmo:',d.get('cosmo'))"
curl -s -m 3 http://127.0.0.1:8080/api/state | head -c 40; echo
for ip in 192.168.178.159 192.168.178.175; do echo "$ip: $(curl -s -m 4 http://$ip/ | grep -io '<title>[^<]*' | head -1)"; done
adb shell cat /data/data/at.magixfly.coretracker/shared_prefs/ct.xml | grep -i cosmo
