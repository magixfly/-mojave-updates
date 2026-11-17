#screenshot
adb shell dumpsys wifi | grep -m2 -E 'mWifiInfo SSID|^mWifiInfo' | cut -c1-160
adb shell ip -4 addr | grep -E 'inet ' | cut -c1-80
adb logcat -d -t 3000 | grep -iE 'CTBOX|api/box|Report' | tail -6 | cut -c1-160
