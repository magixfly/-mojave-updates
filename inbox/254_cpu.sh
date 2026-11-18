top -b -n 2 -d 2 -o %CPU | awk '/^top -/{n++} n==2' | head -16
ps -eo pid,pcpu,rss,args --sort=-pcpu | head -8 | cut -c1-200
