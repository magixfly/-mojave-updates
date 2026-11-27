ls -la /data/data/at.magixfly.coretracker/files/ | head -30
head -c 300 /data/data/at.magixfly.coretracker/files/radars.json; echo
grep -o "\"type\"" /data/data/at.magixfly.coretracker/files/radars.json | wc -l
