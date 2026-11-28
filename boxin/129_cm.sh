F=$(grep -rl "qcrild" /vendor/bin/*.sh /vendor/etc/init/hw/*.rc 2>/dev/null); echo "$F"
for f in $F; do echo "--- $f"; grep -n -B4 -A4 "qcrild" $f | head -60; done
echo ==; getprop | grep -iE "class_main|init.svc.vendor.class_main|vendor.class" 
