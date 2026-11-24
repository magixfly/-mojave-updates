(setsid sh -c "sleep 5; pkill -f ct/run.sh; pkill ld-musl; sleep 2; am force-stop at.magixfly.coretracker; sleep 2; monkey -p at.magixfly.coretracker -c android.intent.category.LAUNCHER 1" >/dev/null 2>&1 </dev/null &)
echo ok
