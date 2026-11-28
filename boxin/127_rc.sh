grep -vE "^\s*#|^\s*$" /vendor/etc/init/qcrild.rc | head -40
echo ==; getprop ro.vendor.radio.noril; getprop ro.radio.noril; getprop persist.vendor.radio.noril; getprop ro.telephony.default_network; getprop ro.boot.hardware.sku; getprop vendor.radio.noril
