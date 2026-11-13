#nobox
# Box per Debugging-Port verbinden, ADB auf 5555, und ADB dauerhaft beim Start aktiv (USB-Debugging an) – vom User freigegeben
B=172.20.10.14
adb connect $B:39855; sleep 2
adb -s $B:39855 tcpip 5555; sleep 4; adb connect $B:5555; sleep 1
A="adb -s $B:5555 shell"
echo "--- vorher"; $A "getprop ro.debuggable; getprop persist.sys.usb.config; getprop persist.adb.tcp.port; settings get global adb_enabled; settings get global adb_wifi_enabled"
$A "settings put global adb_enabled 1; setprop persist.adb.tcp.port 5555"
echo "--- nachher"; $A "settings get global adb_enabled; getprop persist.adb.tcp.port"
echo "--- /data/adb"; $A "ls -la /data/adb 2>&1 | head; ls /data/adb/service.d /data/adb/post-fs-data.d 2>&1 | head"
echo "--- adbd init"; $A "grep -rl adbd /system/etc/init /vendor/etc/init 2>/dev/null | head; getprop init.svc.adbd"
