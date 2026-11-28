dumpsys phone 2>/dev/null | grep -iE "cardState|mCardState|CARDSTATE|simState|PIN|iccid|mUiccSlot|isActive|PersoState|AppState" | head -20 | cut -c1-220
echo ==; dumpsys telephony.registry | grep -iE "simState|CarrierName" | head -5 | cut -c1-200
echo ==; logcat -d -b radio -t 3000 2>/dev/null | grep -iE "sim|card|uicc|ICC" | tail -12 | cut -c1-220
