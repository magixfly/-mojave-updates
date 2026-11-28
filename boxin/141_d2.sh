svc data disable; sleep 2; svc data enable; sleep 25
dumpsys telephony.registry | grep -E "mDataConnectionState" | head -1
ip -o addr | grep -iE "rmnet" | grep "inet " | cut -c1-120
logcat -d -t 4000 | grep -E "SETUP_DATA_CALL DataCallResponse" | tail -1 | cut -c1-200
dumpsys connectivity | grep -E "^  NetworkAgentInfo" | cut -c1-110 | head -4
