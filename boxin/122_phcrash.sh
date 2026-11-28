logcat -d -t 6000 | grep -E "FATAL EXCEPTION|Process: com.android.phone|AndroidRuntime" -A8 | grep -E "FATAL|Process|Exception|Caused|at com|at android" | head -25 | cut -c1-230
echo ==; logcat -d -t 6000 | grep -iE "am_crash|am_proc_died.*phone|ActivityManager.*com.android.phone" | tail -5 | cut -c1-230
echo ==; dumpsys dropbox --print 2>/dev/null | grep -A12 "system_app_crash" | head -30 | cut -c1-230
