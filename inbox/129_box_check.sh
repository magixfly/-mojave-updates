#!/bin/bash
#nobox
echo "--- Pi WLAN"; iwgetid -r; iw dev wlan0 link | grep -E "freq|signal"
echo "--- Geräte"; curl -s -m 60 -X POST -d '{}' localhost:8080/api/devices | head -c 1500; echo
curl -s -m 5 localhost:8080/api/devices | head -c 1500; echo
