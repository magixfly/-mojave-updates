#screenshot
U=https://raw.githubusercontent.com/magixfly/-mojave-updates/carlin/apk/CoreTracker.apk
F=/data/local/tmp/ct_update.apk
curl -sL -o $F "$U?t=$(date +%s)"
setsid sh -c "pm install -r $F; sleep 2; am start -n at.magixfly.coretracker/.MainActivity" </dev/null >/data/local/tmp/inst.log 2>&1 &
sleep 25
cat /data/local/tmp/inst.log
