#screenshot
input tap 1866 36
sleep 2
logcat -d -b all -t 8000 | grep -iE "CTBLE" | tail -15
