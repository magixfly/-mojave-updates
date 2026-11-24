dumpsys wifi | grep -iE "low.?latency|WifiLock|mHighPerf|scanthrottl|ScanThrottle|mLastScan|single scan" | head -15
echo "=== Scan 2"
cmd wifi start-scan; sleep 12
cmd wifi list-scan-results | grep -iE "BSSID|Media|XVII|Optimus"
echo "=== wpa_cli"
for i in wlan0; do wpa_cli -i $i scan >/dev/null 2>&1; sleep 6; wpa_cli -i $i scan_results 2>&1 | head -20; done
ls /data/vendor/wifi/wpa/sockets /data/vendor/wifi/wpa 2>&1 | head
