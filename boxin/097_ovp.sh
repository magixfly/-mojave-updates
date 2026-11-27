Q='[out:json][timeout:12];way(around:350,48.2050,15.5300)[highway~"^(motorway|trunk|primary)$"];out tags geom;'
for H in overpass-api.de lz4.overpass-api.de overpass.kumi.systems maps.mail.ru/osm/tools/overpass; do
 S=$(date +%s%N); C=$(curl -s -o /data/local/tmp/o.json -w "%{http_code}" --max-time 20 --data-urlencode "data=$Q" "https://$H/api/interpreter"); E=$(date +%s%N)
 echo "$H http=$C $(( (E-S)/1000000 )) ms size=$(wc -c </data/local/tmp/o.json) maxspeed=$(grep -o '"maxspeed": "[0-9]*"' /data/local/tmp/o.json | sort | uniq -c | head -3 | tr '\n' ' ')"
done
