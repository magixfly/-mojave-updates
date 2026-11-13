#nobox
# Box per Debugging-Port verbinden und ADB auf festen Port 5555 stellen
adb connect 172.20.10.14:42243; sleep 2
adb -s 172.20.10.14:42243 tcpip 5555; sleep 4
adb connect 172.20.10.14:5555; adb devices
