# Box: Android, CPU, Speicher, Root, Python/Termux
B=192.168.178.235:5555
adb connect $B >/dev/null 2>&1
adb -s $B shell 'getprop ro.build.version.release; getprop ro.build.version.sdk; getprop ro.product.cpu.abi; getprop ro.product.model; getprop ro.board.platform; cat /proc/cpuinfo | grep -m1 -i hardware; nproc; cat /proc/meminfo | head -2; df -h /data | tail -1; id; su -c id 2>&1 | head -1; which python3 toybox busybox 2>/dev/null; pm list packages | grep -i -E "termux|python|chaquo" ; ls /dev/ttyACM* 2>/dev/null; getprop persist.sys.timezone; dumpsys bluetooth_manager 2>/dev/null | grep -m3 -i -E "enabled|state"'
