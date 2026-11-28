uptime
echo "== SIM"; getprop gsm.sim.state; getprop gsm.sim.operator.alpha; getprop gsm.operator.alpha; getprop gsm.network.type
dumpsys telephony.registry | grep -E "mServiceState|mSignalStrength" | head -2 | cut -c1-330
content query --uri content://telephony/carriers/preferapn 2>/dev/null | cut -c1-200
ip addr | grep -A2 rmnet | grep "inet "
ps -A -o PID,STIME,NAME | grep -iE "com.android.phone|qcrild|rild"
logcat -d -b radio -t 400 2>/dev/null | grep -iE "Sim \{" | tail -2 | cut -c1-200
