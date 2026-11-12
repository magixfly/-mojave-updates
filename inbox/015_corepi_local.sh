#screenshot
# löst die Box corepi.local auf?
adb shell ping -c1 -W2 corepi.local 2>&1 | head -2
adb shell am start -a android.intent.action.VIEW -d 'http://corepi.local:8080/' com.android.chrome
sleep 10
