ps -A | grep -iE "netmgr" || echo "netmgrd not running"
setsid /vendor/bin/netmgrd </dev/null >/data/local/tmp/nm.log 2>&1 &
sleep 8; ps -A | grep -iE "netmgr"
svc data disable; sleep 2; svc data enable; sleep 20
dumpsys telephony.registry | grep -E "mDataConnectionState" | head -1
ip -o addr | grep -iE "rmnet" | cut -c1-120
logcat -d -t 3000 | grep -E "SETUP_DATA_CALL DataCallResponse" | tail -1 | cut -c1-200
