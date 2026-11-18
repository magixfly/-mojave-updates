#nobox
# Neuer Backpack-MAC = Mojave: als Auto, Hauptansicht, Name MOJAVE
curl -s -X POST localhost:8080/api/sender -H 'Content-Type: application/json' -d '{"mac":"46:E8:8D:5C:B4:65","slot":1,"type":"car","sym":1,"col":"1a8cff","name":"MOJAVE"}'; echo
grep -E "^senders" /home/user1/Bodenstation/config.txt | cut -c1-120
