cd /data/local/tmp/ct/bodenstation && rm -f server.py.v* *.v[0-9]* kiosk.sh.v309; ls | wc -l; grep -c . config.txt; ls rides 2>/dev/null | wc -l
am force-stop at.magixfly.coretracker; sleep 1; monkey -p at.magixfly.coretracker -c android.intent.category.LAUNCHER 1 >/dev/null 2>&1
sleep 60
ps -A | grep -E "ld-musl|run.sh"
cat /data/local/tmp/ct/run.log; tail -25 server.log
curl -s 127.0.0.1:8080/api/state | head -c 300; echo
