grep -rhE "^service " /vendor/etc/init/ 2>/dev/null | grep -iE "netmgr|data|ipacm|port-bridge|dpm|cnd|qti" | cut -c1-100 | head -15
echo ==; getprop | grep -iE "init.svc.*(netmgr|data|ipacm|port|cnd|dpm|qti)" | cut -c1-80
