grep -v "^#" /vendor/etc/init/qcrild.rc | grep -v "^ *$" | head -45
echo ==; grep -rh -B2 -A3 "qcrild" /vendor/etc/init/hw/*.rc /vendor/etc/init/*.rc 2>/dev/null | grep -E "^on |start|enable" | head -10
