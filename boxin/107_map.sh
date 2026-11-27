#screenshot
logcat -d -t 40000 | grep -E "CTMAP|TileStore|Updater|CTUPD" | tail -12
ps -A -o PID,STIME,NAME | grep coretracker
uptime
