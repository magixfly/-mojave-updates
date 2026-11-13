#nobox
# Netz prüfen: Pi-Band, Box erreichbar?, CosmoStreamer?
nmcli -f IN-USE,SSID,CHAN,FREQ,SIGNAL dev wifi list 2>&1 | grep -E '^\*'
GW=$(ip route | awk '/^default/{print $3; exit}'); echo "Gateway $GW"; hostname -I
ping -c 6 -i 0.3 -q $GW | tail -1
. ~/adbx/env.sh 2>/dev/null; adb connect $GW:5555 2>&1 | tail -1
adb -s $GW:5555 shell "dumpsys wifi | grep -iE 'mSoftApInfo|SoftApInfo\{|frequency=|mBand' | head -5; ip neigh | grep -v FAILED" 2>&1 | cut -c1-200 | head -12
for i in $(seq 2 30); do h=${GW%.*}.$i; curl -s -m 1 http://$h/ 2>/dev/null | grep -qi '<title>cosmostreamer' && echo "CosmoStreamer: $h"; done
