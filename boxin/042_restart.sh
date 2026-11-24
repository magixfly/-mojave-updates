setsid sh -c 'sleep 5; am force-stop at.magixfly.coretracker; sleep 2; am start -n at.magixfly.coretracker/.MainActivity' >/dev/null 2>&1 &
echo neustart in 5 s
