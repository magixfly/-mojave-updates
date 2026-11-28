getprop | grep -iE "sim|ril|radio|baseband|modem" | grep -v "persist.sys" | head -30 | cut -c1-200
echo "== flight"; settings get global airplane_mode_on
echo "== subs"; dumpsys isub 2>/dev/null | grep -iE "simSlotIndex|displayName|carrierName|mcc|iccid" | head -8 | cut -c1-200
echo "== phone"; dumpsys telephony.registry | grep -iE "mPhoneCapability|mSimState|activeSub|mServiceState" | head -4 | cut -c1-200
echo "== usb/modem"; ls /dev | grep -iE "ttyUSB|cdc-wdm|ttyACM|smd" | head; lsusb 2>/dev/null | head
uptime
