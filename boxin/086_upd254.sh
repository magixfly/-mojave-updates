U=https://raw.githubusercontent.com/magixfly/-mojave-updates/carlin/apk/CoreTracker.apk
F=/data/local/tmp/ct_update.apk
(curl -sL -o $F "$U?t=$(date +%s)" || wget -q -O $F "$U" || toybox wget -q -O $F "$U") 2>&1
ls -la $F
setsid sh -c 'pm install -r /data/local/tmp/ct_update.apk; sleep 2; am start -n at.magixfly.coretracker/.MainActivity' </dev/null >/data/local/tmp/inst.log 2>&1 &
sleep 20
cat /data/local/tmp/inst.log
dumpsys package at.magixfly.coretracker | grep -m1 versionName
