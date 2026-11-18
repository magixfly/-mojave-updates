#nobox
sleep 40; grep fpvstat /tmp/tracker_dbg.txt | tail -2 | cut -c1-300
top -b -n 2 -d 4 -o %CPU | awk "/^top -/{n++} n==2" | sed -n "3p;8,10p" | cut -c1-100
vcgencmd measure_temp
