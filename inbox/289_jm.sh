#nobox
grep fpvstat /tmp/tracker_dbg.txt | tail -3 | cut -c1-260
top -b -n 2 -d 4 -o %CPU | awk "/^top -/{n++} n==2" | sed -n "3p;8,10p" | cut -c1-100
curl -s -m 10 http://192.168.178.159/js/player-jmuxer.js 2>/dev/null | grep -oE "fps[^,;]{0,30}|flushingTime[^,;]{0,20}|maxDelay[^,;]{0,20}|clearBuffer[^,;]{0,20}" | sort -u | head
curl -s -m 10 http://192.168.178.159/ | grep -o "player-[a-z]*\.js" | sort -u
