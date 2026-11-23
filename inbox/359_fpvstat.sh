#nobox
touch /tmp/claude_remote
echo "== fpvstat letzte 25 (127.0.0.1 = Pi-Kiosk)"; grep fpvstat /tmp/tracker_dbg.txt | tail -25
echo "== Kernel-Meldungen"; dmesg 2>/dev/null | tail -15 || sudo -n dmesg | tail -15
echo "== D-Status Prozesse"; ps -eo stat,pid,comm | awk '$1 ~ /D/'
echo "== Last-Ursache"; cat /proc/pressure/cpu /proc/pressure/io 2>/dev/null
