#nobox
# WLAN-Qualität des CosmoStreamers: Signal/Bitrate laut Cosmo (20 s) + Ping unter Last
timeout 30 python3 tools/cosmows.py 192.168.178.159 2>&1 | grep -o 'int [^;]*' | sort | uniq -c
echo "== Ping Tracker -> Cosmo, 1400 Byte, 100/s, 15 s"; ping -q -c 1500 -i 0.01 -s 1400 -W 1 192.168.178.159 | tail -2
echo "== Tracker-WLAN"; iwconfig wlan0 2>/dev/null | grep -E "Freq|Bit Rate|Quality" ; nmcli -f IN-USE,SSID,CHAN,RATE,SIGNAL dev wifi list 2>/dev/null | grep '^\*'
