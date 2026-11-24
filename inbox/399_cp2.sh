pkill -f "tar cf - tiles"; pkill -f "exec-in"; sleep 1
cd ~/Bodenstation || exit 1
T=/data/local/tmp/ct/bodenstation
tar czf /tmp/bs.tgz --exclude=./tiles --exclude=__pycache__ --exclude=./server.log --exclude='*.bak' --exclude='server.py.v*' --exclude='*.v[0-9]*' .
ls -la /tmp/bs.tgz
adb push /tmp/bs.tgz /data/local/tmp/ct/bs.tgz
adb shell "cd $T && tar xzf ../bs.tgz && rm ../bs.tgz && ls && du -sh . && grep -c . config.txt"
adb shell "am force-stop at.magixfly.coretracker; sleep 1; monkey -p at.magixfly.coretracker -c android.intent.category.LAUNCHER 1 >/dev/null 2>&1"
sleep 50
adb shell "ps -A | grep -E 'ld-musl|run.sh' | head; tail -15 $T/server.log; cat /data/local/tmp/ct/run.log"
adb shell "curl -s 127.0.0.1:8080/api/state | head -c 200"
df -h ~ | tail -1
nohup sh -c "echo start \$(date) > ~/tilecopy.log; adb push --sync tiles $T/ >> ~/tilecopy.log 2>&1; echo end \$? \$(date) >> ~/tilecopy.log" >/dev/null 2>&1 &
echo tilecopy started
