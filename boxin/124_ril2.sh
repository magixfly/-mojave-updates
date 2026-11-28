grep -rhE "^service " /vendor/etc/init/ /odm/etc/init/ 2>/dev/null | grep -iE "ril|radio|qmi|modem" | head -12
echo ==; getprop | grep -E "init.svc" | grep -iE "ril|radio" ; getprop init.svc.vendor.qcrild; getprop init.svc.vendor.qcrild2; getprop init.svc.ril-daemon
echo ==; ls /sys/bus/msm_subsys/devices/ 2>/dev/null; for d in /sys/bus/msm_subsys/devices/*; do echo "$d $(cat $d/name 2>/dev/null) $(cat $d/state 2>/dev/null)"; done 2>/dev/null | head
echo ==; logcat -d -t 20000 | grep -iE "qcrild|RILQ|ril-daemon|modem.*crash|subsys.*modem" | tail -8 | cut -c1-200
