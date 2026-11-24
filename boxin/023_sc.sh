#screenshot
grep -iE "error|Traceback|dns|fail" /data/local/tmp/ct/bodenstation/server.log | tail -8; netstat -tn 2>/dev/null | grep -E ":8080|:8099" | head
