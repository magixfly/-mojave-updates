#screenshot
adb shell dumpsys activity activities | grep -m1 topResumedActivity | cut -c1-140
adb shell dumpsys power | grep -m2 -E 'mWakefulness=|Display Power' 
adb shell "toybox nc -w 2 192.168.178.169 8080 </dev/null && echo nc-ok || echo nc-fail"
adb shell cat /data/data/at.magixfly.coretracker/shared_prefs/ct.xml | grep '"host"'
adb logcat -d -t 4000 | grep -E 'AndroidRuntime|FATAL|coretracker' | tail -6 | cut -c1-170
for i in 1 2 3; do curl -s -m 3 http://127.0.0.1:8080/api/state | python3 -c "import sys,json;b=json.load(sys.stdin).get('box');print('box:', (b or {}).get('txt'))"; sleep 4; done
