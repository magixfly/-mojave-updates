#timeout 60
C=/boot/firmware/fpv-config.txt
sed -i -E "s|^throttle_channel[[:space:]]*=.*|throttle_channel = 1|; s|^steer_channel[[:space:]]*=.*|steer_channel = 4|" $C
grep -E "^(throttle_channel|steer_channel|control_mode|control_enable|throttle_limit_pct)" $C
systemctl restart fpv-bridge; sleep 3; systemctl is-active fpv-bridge fpv-mediamtx
