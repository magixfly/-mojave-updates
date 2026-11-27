logcat -d -t 60000 | grep -E "CTAP|CTWL" | tail -15
echo ==; cmd wifi help 2>/dev/null | grep -A3 -i "start-softap" | head -8
echo ==; dumpsys tethering | grep -E "wlan.*State" | head -3
echo ==; settings get global soft_ap_timeout_enabled; cmd wifi get-softap-supported-features 2>/dev/null | head -2
