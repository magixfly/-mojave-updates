content query --uri content://telephony/siminfo --projection _id:sim_id:display_name:mcc_string:mnc_string:data_roaming 2>/dev/null | head -5 | cut -c1-160
echo "dds=$(settings get global multi_sim_data_call) md=$(settings get global mobile_data) "
S=$(content query --uri content://telephony/siminfo --where "sim_id>=0" --projection _id 2>/dev/null | head -1 | sed 's/.*_id=//'); echo "sub=$S"
[ -n "$S" ] && settings put global multi_sim_data_call $S && settings put global mobile_data$S 1 && echo "dds set"
svc data disable; sleep 2; svc data enable; sleep 20
dumpsys telephony.registry | grep -E "mDataConnectionState" | head -1
ip -o addr | grep -iE "rmnet" | cut -c1-120
dumpsys connectivity | grep -E "^  NetworkAgentInfo" | cut -c1-110 | head -4
