getprop | grep -iE "init.svc.*(ril|qcril|modem|qmi|cnss|vendor.radio|rmt)" | cut -c1-120
echo ==; getprop | grep -iE "ro.boot.baseband|gsm.version.baseband|ro.baseband|vendor.ril|modem.ssr" | cut -c1-150
echo ==; dumpsys dropbox --print 2>/dev/null | grep -A30 "system_app_anr" | grep -E "Process:|Subject|\"main\"|at |Waiting|waiting" | head -20 | cut -c1-200
echo ==; dumpsys dropbox --print 2>/dev/null | grep -A40 "system_app_crash" | grep -E "Exception|Caused|at com.android.settings" | head -8 | cut -c1-200
