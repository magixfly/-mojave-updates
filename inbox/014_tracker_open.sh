#screenshot
# Core Tracker (Pi, Port 8080) in Chrome auf der Box öffnen
curl -s -o /dev/null -w "Pi-Webseite: HTTP %{http_code}\n" http://127.0.0.1:8080/
adb shell am start -a android.intent.action.VIEW -d 'http://172.20.10.2:8080/' com.android.chrome
sleep 10
