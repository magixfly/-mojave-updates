#timeout 90
G=$(ip -4 route show default dev eth1 | awk '{print $3; exit}')
T=$(mktemp -d); cd $T
for f in js/base/ajax_calls.js js/panel/dashboard.js js/base/utils.js index.html; do curl -s -m 8 "http://$G/$f" -o "$(basename $f)"; done
echo "=== where getAuthHeader / login are defined ==="
grep -nE "function (getAuthHeader|getAuthType|doLogin|login|authentication|GetSyncUrl|getValue)|Action=Digest|AuthQop|AuthCnonce|hex_md5\(" *.js index.html | cut -c1-200 | head -30
F=$(grep -lE "function getAuthHeader" *.js index.html | head -1); L=$(grep -nE "function getAuthHeader" $F | head -1 | cut -d: -f1)
echo "=== getAuthHeader in $F from line $L ==="; [ -n "$L" ] && sed -n "${L},$((L+40))p" $F
L2=$(grep -nE "Action=Digest" ajax_calls.js index.html utils.js | head -1); echo "=== login call: $L2 ==="
FF=${L2%%:*}; N=$(echo $L2 | cut -d: -f2); [ -n "$N" ] && sed -n "$((N-25)),$((N+25))p" $FF
echo "=== dashboard.js 80-160 ==="; sed -n 80,160p dashboard.js | cut -c1-180
echo "=== USB interfaces of the stick (AT port?) ==="
ls /dev/ttyACM* /dev/ttyUSB* 2>&1
for d in /sys/bus/usb/devices/*; do [ -f $d/idVendor ] && [ "$(cat $d/idVendor)" = 1286 ] && { echo "$d $(cat $d/idProduct) $(cat $d/product 2>/dev/null)"; for i in $d/*:*; do echo "  $(basename $i) class=$(cat $i/bInterfaceClass) sub=$(cat $i/bInterfaceSubClass) proto=$(cat $i/bInterfaceProtocol) driver=$(basename $(readlink $i/driver) 2>/dev/null)"; done; }; done
echo "[100%] done"
