#nobox
Z=$(grep '^zentrale=' ~/Bodenstation/config.txt | cut -d= -f2 | awk '{print $1}')
for i in 1 2 3 4 5 6; do curl -s --max-time 5 $Z/api/status; echo; sleep 10; done
curl -s --max-time 5 $Z/api/ping; echo
