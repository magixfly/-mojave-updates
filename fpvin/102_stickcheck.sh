#timeout 60
ls -la /dev/ttyUSB* 2>&1
for d in /sys/bus/usb/devices/*; do [ -f $d/idVendor ] && [ "$(cat $d/idVendor)" = 1286 ] && { echo "$d $(cat $d/idProduct)"; for i in $d/*:*; do echo "  $(basename $i) class=$(cat $i/bInterfaceClass) driver=$(basename $(readlink $i/driver) 2>/dev/null)"; done; }; done
dmesg | grep -iE "usb 1-1.1|option|ttyUSB|rndis|eth1" | tail -25
ip -4 addr show eth1 | grep inet
ip -4 route show default
echo "net: $(curl -s -m 5 http://localhost:8080/api/net)"
echo "[100%] done"
