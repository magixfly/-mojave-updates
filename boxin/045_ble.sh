#screenshot
dumpsys bluetooth_manager | grep -iE "CoreTracker|state:|enabled|gatt|connected|LeScan|scanner" | head -25
logcat -d -b all -t 6000 | grep -iE "CTBLE|CoreTracker-ESP|BtGatt.*magixfly" | tail -15
input tap 1860 36
sleep 3
