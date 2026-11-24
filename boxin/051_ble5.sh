#screenshot
logcat -d -b all -t 20000 | grep -iE "CTBLE" | tail -15
sleep 2
