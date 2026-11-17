#nobox
curl -s -m 20 http://192.168.178.175/js/devicesettings.js | grep -n "System" 
curl -s -m 20 http://192.168.178.175/tpl/devicesettings.system.tpl.html | grep -n -iE "reboot|restart|cmd" | head -20
