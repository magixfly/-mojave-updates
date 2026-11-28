dumpsys telephony.registry | grep -E "mServiceState" | head -1 | cut -c1-120
cmd phone help 2>/dev/null | grep -iE "radio" | head -5
cmd phone radio power on 2>&1 | head -2; cmd phone radio-power on 2>&1 | head -2
svc data enable 2>&1 | head -1
sleep 30
echo "sim=$(getprop gsm.sim.state) op=$(getprop gsm.sim.operator.alpha) net=$(getprop gsm.operator.alpha) type=$(getprop gsm.network.type)"
dumpsys telephony.registry | grep -E "mServiceState|mSignalStrength" | head -2 | cut -c1-300
ip addr | grep -A2 rmnet | grep "inet "
content query --uri content://telephony/carriers/preferapn 2>/dev/null | cut -c1-160
