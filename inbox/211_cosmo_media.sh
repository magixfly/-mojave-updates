sleep 30
for i in $(seq 2 254); do timeout 0.4 ping -c1 -W1 192.168.178.$i >/dev/null 2>&1; done
ip neigh | grep -i "dc:a6:32:09:df"
for ip in $(ip neigh | grep -i "dc:a6:32:09:df" | awk '{print $1}'); do echo "$ip: $(curl -s -m 4 http://$ip/ | grep -io '<title>[^<]*' | head -1)"; done
sleep 60
adb shell cat /data/data/at.magixfly.coretracker/shared_prefs/ct.xml | grep -i cosmo
#screenshot
