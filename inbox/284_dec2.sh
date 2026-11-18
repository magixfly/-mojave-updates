#nobox
sleep 45; grep fpvstat /tmp/tracker_dbg.txt | tail -1 | cut -c1-400
top -b -n 2 -d 4 -o %CPU | awk "/^top -/{n++} n==2" | sed -n "3p;8,12p" | cut -c1-100
vcgencmd measure_temp
