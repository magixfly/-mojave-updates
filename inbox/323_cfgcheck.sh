#nobox
cd /home/user1/Bodenstation
grep -E "^(theme|map3d|night|auto_zoom|auto_zoom_lv|orientation|sound)=" config.txt | cut -c1-40
ls -la config.txt; curl -s localhost:8080/api/state | head -c 40; echo
journalctl --user -n 400 --no-pager 2>/dev/null | grep -i "api/set\|cfg\|error\|Traceback" | tail -15
grep -rn "config.txt" *.sh 2>/dev/null | head
