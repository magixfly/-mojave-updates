adb shell "dumpsys wifi | grep -m1 'mWifiInfo'" | cut -c1-200
adb logcat -d -s CTFPV:D | grep CTSTAT | tail -4
adb shell input tap 1868 518
sleep 2
#screenshot
