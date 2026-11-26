getprop persist.adb.tcp.port; getprop service.adb.tcp.port; settings get global adb_wifi_enabled
setprop persist.adb.tcp.port 5555
setprop service.adb.tcp.port 5555
echo set
setsid sh -c 'sleep 20; setprop ctl.restart adbd' </dev/null >/dev/null 2>&1 &
