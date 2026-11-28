for f in /vendor/etc/init/hw/*.rc /vendor/etc/init/*.rc /system/etc/init/*.rc; do grep -n -A5 "class_main\|netmgrd" "$f" 2>/dev/null | sed "s#^#$(basename $f): #" ; done | head -40 | cut -c1-170
echo ==; getprop | grep -iE "init.svc" | grep -iE "class|netmgr" | cut -c1-90
