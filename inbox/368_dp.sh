# Box: kann USB-C Bild ausgeben (DisplayPort Alt Mode)?
touch /tmp/claude_remote
B=$(adb devices | awk '/:5555[[:space:]]+device/{print $1; exit}'); echo "Box $B"
adb -s $B shell 'getprop ro.product.model; getprop ro.board.platform; getprop ro.soc.model; ls /sys/class/typec/ 2>&1; ls /sys/class/drm/ 2>&1; cat /sys/class/typec/port0/*/svid 2>/dev/null; ls -d /sys/class/typec/port0/port0.* 2>/dev/null; dmesg 2>/dev/null | grep -i -m5 -E "displayport|dp_altmode|altmode"; getprop | grep -i -E "dp|hdmi|altmode|usb.config" | head -15; dumpsys display | grep -m5 -E "DisplayDeviceInfo|mDisplayId"'
