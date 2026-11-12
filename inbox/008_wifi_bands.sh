# kann die Box 5 GHz? + DJI-Fehler aus dem Log
adb shell cmd wifi status 2>/dev/null | head -5
adb shell dumpsys wifi | grep -iE 'is5GHzBandSupported|is6GHz|isStaApConcurrency|Supported.*Band|mIs5Ghz' | head -8
adb shell cmd wifi list-scan-results 2>/dev/null | head -25
echo "--- DJI log ---"
adb logcat -d -t 3000 | grep -iE 'goggle|wifi.*connect|bluetooth|ble|livesh|share' | grep -i -E 'dji|go.v5' | tail -25
