#timeout 60
echo "== usb"; lsusb
echo "== net"; ip -br addr
echo "== routes"; ip route
echo "== kernel"; dmesg 2>/dev/null | grep -iE "usb [0-9-]+: (new|Product|Manufacturer)|rndis|cdc_ether|cdc_ncm|usb0|eth1|wwan|option|ttyUSB|usb-storage|sr0" | tail -30
echo "== nm"; nmcli -t -f DEVICE,TYPE,STATE,CONNECTION dev 2>/dev/null
echo "== fpv"; grep -m1 VERSION /opt/fpv/fpvcfg.py; systemctl is-active fpv-bridge fpv-mediamtx; tailscale status 2>/dev/null | head -3
echo "[100%] done"
