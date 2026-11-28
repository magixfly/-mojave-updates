stop vendor.qcrild2; stop vendor.qcrild; sleep 2; start vendor.qcrild; start vendor.qcrild2; sleep 3
kill $(pidof com.android.phone); sleep 45
echo "sim=$(getprop gsm.sim.state) net=$(getprop gsm.operator.alpha) type=$(getprop gsm.network.type)"
dumpsys telephony.registry | grep -E "mDataConnectionState" | head -1
ip -o addr | grep -iE "rmnet" | grep "inet " | cut -c1-120
logcat -d -t 6000 | grep -E "SETUP_DATA_CALL DataCallResponse" | tail -1 | cut -c1-200
