cd /data/local/tmp/ct/bodenstation; ls | wc -l; ls | grep -c "\.v"
(setsid sh /data/local/tmp/ct/run.sh >/dev/null 2>&1 </dev/null &)
sleep 30
ps -A | grep -E "ld-musl|run.sh"
cat /data/local/tmp/ct/run.log; tail -30 /data/local/tmp/ct/bodenstation/server.log
curl -s 127.0.0.1:8080/api/state | head -c 300; echo
logcat -d -t 300 | grep -iE "coretracker|tracker" | tail -15
