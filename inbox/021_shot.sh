#screenshot
sleep 2
adb logcat -d -t 800 | grep -iE "chromium|cr_|webview|coretracker" | tail -15
