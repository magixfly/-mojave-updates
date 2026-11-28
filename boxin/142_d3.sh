logcat -d -b all -t 20000 2>/dev/null | grep -iE "SETUP_DATA_CALL|onDataNetworkSetupDataFailed|Data evaluation|DisallowedReason|data disallowed" | tail -8 | cut -c1-260
