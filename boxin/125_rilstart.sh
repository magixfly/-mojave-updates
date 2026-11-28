grep -rh -A6 "^service vendor.qcrild /" /vendor/etc/init/ 2>/dev/null | head -8
start vendor.qcrild; sleep 20
echo "svc=$(getprop init.svc.vendor.qcrild)"; ps -A | grep -i qcril
echo "sim=$(getprop gsm.sim.state) op=$(getprop gsm.sim.operator.alpha) net=$(getprop gsm.operator.alpha) type=$(getprop gsm.network.type)"
dumpsys telephony.registry | grep -E "mServiceState" | head -1 | cut -c1-200
logcat -d -t 3000 | grep -iE "qcrild|RILQ" | tail -6 | cut -c1-200
