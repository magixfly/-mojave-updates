IF=$(ip -o -4 addr | grep rmnet | awk '{print $2}' | head -1); echo "if=$IF"
ping -c5 -I $IF 1.1.1.1 2>&1 | tail -1
curl -s --interface $IF -o /dev/null -w "down %{speed_download} B/s %{time_total}s\n" --max-time 25 "https://speed.cloudflare.com/__down?bytes=10000000"
head -c 4000000 /dev/urandom > /data/local/tmp/up.bin
curl -s --interface $IF -o /dev/null -w "up %{speed_upload} B/s %{time_total}s\n" --max-time 25 --data-binary @/data/local/tmp/up.bin "https://speed.cloudflare.com/__up"
dumpsys telephony.registry | grep -oE "mLte=CellSignalStrengthLte: rssi=[-0-9]+ rsrp=[-0-9]+ rsrq=[-0-9]+ rssnr=[-0-9]+" | head -1
