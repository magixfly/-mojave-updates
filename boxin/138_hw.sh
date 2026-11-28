grep -rn -B2 -A6 "class_main.sh\|netmgrd" /vendor/etc/init/hw/*.rc /vendor/etc/init/*.rc 2>/dev/null | grep -vE "^\S*-\s*$" | head -40 | cut -c1-160
echo ==; ls /vendor/bin | grep -iE "netmgr|class_main"
echo ==; getprop | grep -iE "svc.*(class_main|netmgr)"
