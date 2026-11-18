#nobox
sleep 50; grep fpvstat /tmp/tracker_dbg.txt | tail -2 | cut -c1-330
top -b -n 2 -d 3 -o %CPU | awk "/^top -/{n++} n==2" | sed -n "3p;8,11p" | cut -c1-100
