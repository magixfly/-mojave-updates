#screenshot
echo "--- Verbindungen:"; nmcli -t -f NAME,TYPE,AUTOCONNECT,AUTOCONNECT-PRIORITY,DEVICE con show
echo "--- WLAN in Reichweite:"; nmcli -t -f SSID,SIGNAL,SECURITY dev wifi list | head -15
for c in $(nmcli -t -f NAME,TYPE con show | grep -i wireless | cut -d: -f1 | grep -i '^CoreTracker'); do sudo nmcli con mod "$c" connection.autoconnect no && echo "CoreTracker autoconnect aus: $c"; done
nmcli -t -f NAME con show | grep -qx "Optimus Prime" && { sudo nmcli con mod "Optimus Prime" connection.autoconnect yes connection.autoconnect-priority 50; timeout 40 sudo nmcli con up "Optimus Prime" 2>&1 | tail -2; }
echo "--- jetzt:"; nmcli -t -f DEVICE,STATE,CONNECTION dev status; ip -4 -br addr
