#nobox
B=172.20.10.14; . ~/adbx/env.sh 2>/dev/null
adb connect $B:42061; sleep 2; adb -s $B:42061 tcpip 5555; sleep 4; adb connect $B:5555; adb devices
