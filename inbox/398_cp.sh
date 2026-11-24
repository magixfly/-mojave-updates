cd ~/Bodenstation || exit 1
grep -o 'VERSION = "[0-9.]*"' server.py
adb shell id
T=/data/local/tmp/ct/bodenstation
adb shell "mkdir -p $T"
tar cf - --exclude=./tiles --exclude=__pycache__ --exclude=./server.log --exclude='*.bak' . | adb exec-in "sh -c 'cd $T && tar xf -'"
adb shell "cd $T && ls | head -40 && du -sh . && grep -c . config.txt"
# start the tracker on the box: restart the app, it starts run.sh itself
adb shell "am force-stop at.magixfly.coretracker; sleep 1; monkey -p at.magixfly.coretracker -c android.intent.category.LAUNCHER 1 >/dev/null 2>&1"
sleep 45
adb shell "ps -A | grep -E 'ld-musl|run.sh' | head; tail -15 $T/server.log; cat /data/local/tmp/ct/run.log"
adb shell "curl -s 127.0.0.1:8080/api/state | head -c 300"
# map tiles (1.8 GB) in the background, progress in ~/tilecopy.log
nohup sh -c "echo start \$(date) > ~/tilecopy.log; tar cf - tiles | adb exec-in \"sh -c 'cd $T && tar xf -'\" && echo done \$(date) >> ~/tilecopy.log || echo fail >> ~/tilecopy.log" >/dev/null 2>&1 &
echo tilecopy started
