echo "simnum=$(getprop gsm.sim.operator.numeric) netnum=$(getprop gsm.operator.numeric)"
echo "always_on=$(settings get global mobile_data_always_on) mobile_data=$(settings get global mobile_data) mobile_data1=$(settings get global mobile_data1)"
ip -o addr | grep -iE "rmnet|ccmni|wwan" | cut -c1-120
dumpsys telephony.registry | grep -E "mDataConnectionState|mDataConnectionNetworkType" | head -2
dumpsys connectivity | grep -E "^  NetworkAgentInfo" | cut -c1-160 | head -4
