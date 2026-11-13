# Box: SIM/Mobilfunk und Hotspot-Fähigkeit (5 GHz) prüfen – ändert nichts
adb shell getprop gsm.operator.alpha; adb shell getprop gsm.network.type; adb shell getprop gsm.sim.state
adb shell settings get global mobile_data
adb shell "cmd wifi status" 2>&1 | head -5
adb shell "cmd wifi get-softap-supported-features" 2>&1 | head -5
adb shell "dumpsys wifi | grep -iE 'SoftApConfiguration|mBand|apBand|isStaApConcurrencySupported|5GHz' | head -12"
