# Box: Infos + App 1.87 (ANDROID_SERIAL setzt die Bridge)
adb shell 'getprop ro.build.version.release; getprop ro.build.version.sdk; getprop ro.product.cpu.abi; getprop ro.product.model; getprop ro.board.platform; nproc; head -2 /proc/meminfo; df -h /data | tail -1; su -c id 2>&1 | head -1; pm list packages | grep -i -E "termux|python|tailscale|wireguard"; dumpsys bluetooth_manager 2>/dev/null | grep -m2 -i "enabled"'
adb install -r apk/CoreTracker.apk 2>&1 | tail -1
adb shell dumpsys package at.magixfly.coretracker | grep -m1 versionName
