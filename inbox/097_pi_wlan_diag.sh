#nobox
# Pi: WLAN-Diagnose (Unterspannung, Stromsparmodus, Kanal, USB)
vcgencmd get_throttled; vcgencmd measure_temp
nmcli -f IN-USE,SSID,CHAN,FREQ,SIGNAL,RATE dev wifi list 2>&1 | grep '^\*'
iw dev wlan0 get power_save 2>&1
for c in $(nmcli -t -f NAME,TYPE con show | grep wireless | cut -d: -f1); do echo "$c: powersave=$(nmcli -g 802-11-wireless.powersave con show "$c")"; done
lsusb -t 2>&1 | head -20
ping -c 20 -i 0.3 -q $(ip route | awk '/^default/{print $3; exit}') | tail -2
dmesg 2>/dev/null | grep -iE "under-voltage|brcmf|wlan0" | tail -8
