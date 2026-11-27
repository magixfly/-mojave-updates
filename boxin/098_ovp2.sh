Q='[out:json][timeout:12];way(around:350,48.1795,15.5845)[highway~"^(motorway|trunk|primary)$"];out tags geom;'
for UA in "Dalvik/2.1.0 (Linux; U; Android 15)" "CoreDash/2.61 (private car display)"; do
 S=$(date +%s%N); C=$(curl -s -A "$UA" -o /data/local/tmp/o.json -w "%{http_code}" --max-time 20 "https://overpass-api.de/api/interpreter?data=$(echo "$Q" | sed 's/ /%20/g;s/"/%22/g;s/\[/%5B/g;s/\]/%5D/g;s/~/%7E/g;s/\^/%5E/g;s/|/%7C/g;s/\$/%24/g')"); E=$(date +%s%N)
 echo "UA=$UA http=$C $(( (E-S)/1000000 ))ms size=$(wc -c </data/local/tmp/o.json) $(grep -o '"maxspeed": "[0-9]*"' /data/local/tmp/o.json | sort | uniq -c | tr '\n' ' ')"
done
logcat -d -t 5000 | grep -i "CTLIVE\|overpass" | tail -5
