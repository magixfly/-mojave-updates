#nobox
# CosmoStreamer: was meldet er selbst (CPU, Temperatur, Bitrate)? 20 s mitschneiden
timeout 25 python3 tools/cosmows.py 192.168.178.175 2>&1 | grep -v '"ifaces"' | cut -c1-300 | sort | uniq -c | sort -rn | head -25
