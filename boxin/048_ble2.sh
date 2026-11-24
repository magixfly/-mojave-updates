#screenshot
logcat -d -b all -t 8000 | grep -iE "CTBLE|CoreTracker-ESP|BleEsp" | tail -20
dumpsys bluetooth_manager | grep -iE "CoreTracker|ConnectionState" | head -8
