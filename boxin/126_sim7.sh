echo "svc=$(getprop init.svc.vendor.qcrild) sim=$(getprop gsm.sim.state) op=$(getprop gsm.sim.operator.alpha) net=$(getprop gsm.operator.alpha) type=$(getprop gsm.network.type)"
ps -A -o PID,STIME,NAME | grep -E "com.android.phone|qcrild"
dumpsys telephony.registry | grep -E "mServiceState|mSignalStrength" | head -2 | cut -c1-260
ip addr | grep -A2 rmnet | grep "inet "
grep -rlE "start vendor.qcrild|vendor.qcrild" /vendor/etc/init/*.rc 2>/dev/null | head -3; grep -rhE -B3 "start vendor.qcrild$" /vendor/etc/init/ 2>/dev/null | head -12
