sleep 20
top -b -n 1 -m 5 | sed -n 4,9p
dumpsys activity top | grep -m3 -E "ACTIVITY|mResumed"
