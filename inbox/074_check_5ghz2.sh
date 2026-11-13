#screenshot
# Prüfen: Pi im 5-GHz-Hotspot, Box und CosmoStreamer erreichbar
cat /sys/module/cfg80211/parameters/ieee80211_regdom
nmcli -f IN-USE,SSID,CHAN,FREQ,SIGNAL dev wifi list 2>&1 | grep '^\*'
hostname -I
for h in cosmostreamer.local 172.20.10.10; do printf "%s: " $h; curl -s -m 3 http://$h/ | grep -io '<title>[^<]*' | head -1; echo; done
