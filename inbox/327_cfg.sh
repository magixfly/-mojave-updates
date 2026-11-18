#nobox
cd /home/user1/Bodenstation
grep -E "^(theme|map3d|night|orientation)=" config.txt | cut -c1-30
ls -la --time-style=full-iso config.txt*; ls *.log 2>/dev/null; grep -rl "theme=glass" . 2>/dev/null | head
ps aux | grep -c "[s]erver.py"; ps aux | grep "[s]erver.py" | cut -c1-150
