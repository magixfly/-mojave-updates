sh /vendor/bin/init.class_main.sh 2>&1 | tail -3
sleep 40
getprop | grep -E "init.svc.vendor.(qcrild|ril)" 
echo "sim=$(getprop gsm.sim.state) op=$(getprop gsm.sim.operator.alpha) net=$(getprop gsm.operator.alpha) type=$(getprop gsm.network.type)"
ps -A -o PID,STIME,NAME | grep -E "com.android.phone|qcrild"
dumpsys telephony.registry | grep -E "mServiceState|mSignalStrength" | head -2 | cut -c1-260
ip addr | grep -A2 rmnet | grep "inet "
