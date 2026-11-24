(setsid sh -c "sleep 8; am force-stop at.magixfly.coretracker; sleep 2; monkey -p at.magixfly.coretracker -c android.intent.category.LAUNCHER 1" >/dev/null 2>&1 </dev/null &)
echo restart scheduled
