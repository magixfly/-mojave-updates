#nobox
grep -n "chromium" ~/Bodenstation/kiosk.sh | cut -c1-400
ps -eo pid,pcpu,args --sort=-pcpu | grep -i chrom | head -6 | cut -c1-230
ls /dev/video1* 2>/dev/null; cat /proc/device-tree/model; echo
