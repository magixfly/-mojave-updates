#screenshot
top -b -n 1 -m 12 | head -20
cat /proc/loadavg
dumpsys meminfo at.magixfly.coretracker | grep -E "TOTAL|Native Heap|Dalvik Heap" | head -4
logcat -d -t 400 | grep -iE "coretracker|chromium|Choreographer|ANR|slow" | tail -25
