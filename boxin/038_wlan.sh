cmd wifi status | head -20
echo "=== Scan"
cmd wifi start-scan; sleep 6
cmd wifi list-scan-results | grep -iE "BSSID|Media"
echo "=== Hilfe connect"
cmd wifi help 2>&1 | grep -iA12 "connect-network" | head -30
echo "=== gespeicherte Netze"
cmd wifi list-networks
