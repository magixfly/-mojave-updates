# corepi: WLAN-Land prüfen und auf AT setzen, damit 5-GHz-Hotspot (XVII) geht
echo "--- vorher"; iw reg get 2>/dev/null | head -4; sudo -n raspi-config nonint get_wifi_country 2>&1
iwgetid -r; iw dev wlan0 link | grep -E "SSID|freq"
echo "--- setzen"; sudo -n raspi-config nonint do_wifi_country AT 2>&1; sudo -n iw reg set AT 2>&1
echo "--- nachher"; iw reg get 2>/dev/null | head -4; sudo -n raspi-config nonint get_wifi_country 2>&1
echo "--- XVII sichtbar?"; sudo -n iw dev wlan0 scan 2>/dev/null | grep -B8 "SSID: XVII" | grep -E "freq|SSID"
nmcli -f NAME,TYPE,AUTOCONNECT con show 2>/dev/null | head; nmcli -g 802-11-wireless.band con show XVII 2>/dev/null
