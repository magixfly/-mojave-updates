#timeout 60
for d in /dev/video*; do n=$(v4l2-ctl -d $d --info 2>/dev/null | grep -m1 "Card type"); case "$n" in *bcm2835*|*unicam*|*rp1*|*pispbe*|"") continue;; esac; echo "== $d $n"; v4l2-ctl -d $d --list-formats-ext 2>/dev/null | grep -E "^\s*\[|Size|Interval" | head -80; done
grep -E "^cam2_|^video_" /boot/firmware/fpv-config.txt
pgrep -af "v4l2src|usbcam" | cut -c1-200
echo "[100%] done"
