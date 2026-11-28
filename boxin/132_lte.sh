dumpsys telephony.registry | grep -oE "mLte=CellSignalStrengthLte: rssi=[-0-9]+ rsrp=[-0-9]+ rsrq=[-0-9]+ rssnr=[-0-9]+[^,]*level=[0-9]" | head -1
dumpsys telephony.registry | grep -oE "PreciseDataConnectionState[^}]{0,300}" | grep -iE "state=[0-9]|apn" | head -3 | cut -c1-300
content query --uri content://telephony/carriers --where "apn='drei.at'" --projection _id:name:numeric 2>/dev/null
ID=$(content query --uri content://telephony/carriers --where "apn='drei.at' AND name='Planet 3'" --projection _id 2>/dev/null | head -1 | sed 's/.*_id=//')
[ -n "$ID" ] && content insert --uri content://telephony/carriers/preferapn --bind apn_id:i:$ID && echo "preferapn set $ID"
sleep 8; content query --uri content://telephony/carriers/preferapn 2>/dev/null | cut -c1-120
ip addr | grep -B1 -A3 "rmnet" | grep "inet " ; ping -c2 -W3 8.8.8.8 >/dev/null && echo ping_ok
dumpsys connectivity | grep -E "NetworkAgentInfo.*(CELLULAR|MOBILE)" | head -1 | cut -c1-200
