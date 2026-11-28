echo "== SIM/Netz"; getprop gsm.sim.state; getprop gsm.operator.alpha; getprop gsm.sim.operator.alpha; getprop gsm.network.type; getprop gsm.operator.numeric; getprop gsm.sim.operator.numeric
echo "== Registrierung"; dumpsys telephony.registry | grep -E "mServiceState|mSignalStrength|mDataConnectionState|mDataConnectionNetworkType" | head -6 | cut -c1-400
echo "== APN"; content query --uri content://telephony/carriers/preferapn 2>/dev/null | cut -c1-300
content query --uri content://telephony/carriers --where "numeric='23205' OR numeric='23210'" --projection name:apn:user:type:current 2>/dev/null | head -8
echo "== Daten"; settings get global mobile_data; ip addr show | grep -A2 rmnet | grep inet; ping -c2 -W3 -I rmnet_data2 1.1.1.1 2>&1 | tail -2
dumpsys connectivity | grep -E "NetworkAgentInfo.*CELLULAR" | head -2 | cut -c1-300
