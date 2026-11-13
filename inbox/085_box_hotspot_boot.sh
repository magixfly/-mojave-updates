# Box: ADB dauerhaft auf Port 5555 (vom User 13.11. 19:38 freigegeben) + prüfen, wie der Hotspot beim Start automatisch angehen kann
adb shell id
adb shell setprop persist.adb.tcp.port 5555; adb shell getprop persist.adb.tcp.port
echo "--- ADB-Bestätigung aktiv?"; adb shell getprop ro.adb.secure
echo "--- su für Apps?"; adb shell "ls -l /system/xbin/su /system/bin/su /sbin/su 2>&1"; adb shell getprop ro.build.type
echo "--- Befehle"; adb shell "cmd -l | grep -iE 'tether|wifi|connectivity'"
adb shell "cmd wifi help 2>/dev/null | grep -iA3 softap | head -30"
adb shell "cmd tethering help 2>&1 | head -10"
echo "--- Startskripte?"; adb shell "ls /system/etc/init/ | head -40; ls -d /data/adb /data/local/userinit* 2>&1"
