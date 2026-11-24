#nobox
df -h / ~/Bodenstation 2>&1
lsblk -d -o NAME,SIZE,MODEL 2>&1
du -sh ~/Bodenstation/tiles/* 2>&1
curl -s --max-time 3 http://127.0.0.1:8080/api/state | head -c 20; echo
