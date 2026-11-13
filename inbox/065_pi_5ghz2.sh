# corepi: WLAN-Land ohne sudo prüfen
tr ' ' '\n' < /proc/cmdline | grep -i regdom; cat /sys/module/cfg80211/parameters/ieee80211_regdom 2>/dev/null
nmcli general permissions | grep -iE "wifi|network.control|modify"
nmcli -f IN-USE,SSID,CHAN,FREQ,SIGNAL dev wifi list 2>&1 | head -15
nmcli -g 802-11-wireless.band,802-11-wireless.channel con show XVII
cat /proc/device-tree/model; echo; id
