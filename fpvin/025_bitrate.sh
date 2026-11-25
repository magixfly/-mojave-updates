#timeout 60
C=/boot/firmware/fpv-config.txt
sed -i -E "s|^cam2_bitrate_kbps[[:space:]]*=.*|cam2_bitrate_kbps = 3500|" $C
python3 /opt/fpv/apply_config.py | tail -1; timeout 25 systemctl restart fpv-mediamtx; sleep 5
grep -E "^(cam2_bitrate_kbps|cam2_width|cam2_height|video_bitrate_kbps)" $C; grep -n "usbcam" -A1 /etc/fpv/mediamtx.yml | cut -c1-170 | tail -2
