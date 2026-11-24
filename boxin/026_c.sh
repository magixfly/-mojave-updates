ps -A | grep -E "ld-musl|run.sh"; tail -3 /data/local/tmp/ct/run.log; logcat -d -t 2000 | grep -iE "coretracker" | grep -iE "exception|error" | tail -8
