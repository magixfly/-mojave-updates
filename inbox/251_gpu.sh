grep -o "chromium[^\"]*" ~/Bodenstation/kiosk.sh | head -3
ps -eo args | grep -m1 "chromium.*kiosk" | tr ' ' '\n' | grep -- "--" | head -30
ls /dev/video1* 2>&1 | head; vcgencmd get_mem gpu 2>/dev/null; grep -i "dtoverlay=vc4\|gpu_mem" /boot/firmware/config.txt
