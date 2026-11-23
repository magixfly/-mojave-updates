#nobox
# 23.11.: FPV friert im Kiosk ein - Diagnose
touch /tmp/claude_remote
curl -s localhost:8080/api/devices | python3 -c "import json,sys;print('cosmo',(json.load(sys.stdin).get('d') or {}).get('cosmo'))"
echo "== Last"; uptime; free -m; vcgencmd measure_temp; vcgencmd get_throttled; vcgencmd get_mem gpu 2>/dev/null
echo "== Top"; top -b -n1 -o %CPU | head -15
echo "== Chromium Start"; ps -eo args | grep -m1 -E "[c]hromium.*(kiosk|app=)" | tr ' ' '\n' | grep -E "^--" 
echo "== Chromium Speicher"; ps -C chromium,chromium-browser -o rss= | awk '{s+=$1} END {print s/1024 " MB"}'
echo "== Swap/OOM"; swapon --show; journalctl -k --since "-30 min" 2>/dev/null | grep -i -E "oom|killed" | tail -5
echo "== config.txt"; grep -v -E "^#|^$" /boot/firmware/config.txt
echo "== Zram"; ls /dev/zram* 2>/dev/null; cat /etc/os-release | grep PRETTY; chromium --version 2>/dev/null || chromium-browser --version
echo "== V4L2 Decoder"; ls /dev/video1* 2>/dev/null
sleep 20; echo "== Top nach 20 s"; top -b -n1 -o %CPU | head -10
