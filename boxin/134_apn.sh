content insert --uri content://telephony/carriers/preferapn --bind apn_id:i:294 && echo set294
svc data disable; sleep 2; svc data enable
sleep 20
content query --uri content://telephony/carriers/preferapn 2>/dev/null | cut -c1-100
dumpsys telephony.registry | grep -E "mDataConnectionState" | head -1
ip -o addr | grep -iE "rmnet" | cut -c1-120
dumpsys connectivity | grep -E "^  NetworkAgentInfo" | cut -c1-120 | head -4
logcat -d -t 3000 | grep -iE "DataNetwork|setupData|DataProfile|apn" | tail -6 | cut -c1-220
