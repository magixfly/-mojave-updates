#screenshot
getprop ro.build.version.release; getprop ro.product.model; getprop ro.product.cpu.abi; nproc; head -2 /proc/meminfo; df -h /data | tail -1
dumpsys package at.magixfly.coretracker | grep -m1 versionName
ip -4 addr show wlan0 | grep inet
