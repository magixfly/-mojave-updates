logcat -d -b crash -t 200 2>/dev/null | grep -E "Process:|FATAL|Exception|at " | head -14 | cut -c1-220
echo ==; ps -A -o PID,STIME,NAME | grep -iE "phone|ril|qcrild|tdc" | head
echo ==; logcat -d -t 2000 | grep -iE "AndroidRuntime|qcrild|RILJ" | tail -8 | cut -c1-220
