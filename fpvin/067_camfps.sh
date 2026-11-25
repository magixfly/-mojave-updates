#timeout 60
for d in /dev/v4l-subdev*; do n=$(cat /sys/class/video4linux/$(basename $d)/name 2>/dev/null); echo "$d = $n"; done
S=$(for d in /dev/v4l-subdev*; do grep -qi "imx" /sys/class/video4linux/$(basename $d)/name 2>/dev/null && echo $d; done | head -1)
echo "sensor: $S"; v4l2-ctl -d $S --list-ctrls 2>&1 | grep -iE "blank|pixel_rate|link_freq|exposure|gain" | tr -s ' ' | cut -c1-150
v4l2-ctl -d $S --get-subdev-fmt 2>&1 | grep -iE "Width|Mediabus" | tr -s ' \t' ' ' | tr '\n' ';'; echo
grep -E "imx|camera_auto|dtoverlay" /boot/firmware/config.txt | tr '\n' ';'; echo
dmesg | grep -i imx | tail -4 | cut -c1-160
uname -r; dpkg -l | grep -E "libcamera0|rpicam-apps" | awk '{print $2, $3}' | tr '\n' ';'; echo
