ps -A | grep -E "ld-musl|run.sh"
cat /data/local/tmp/ct/run.log
tail -20 /data/local/tmp/ct/bodenstation/server.log
curl -s 127.0.0.1:8080/api/state | head -c 300; echo
