#timeout 900
C=/boot/firmware/fpv-config.txt
setkey() { if grep -qE "^$1[[:space:]]*=" $C; then sed -i -E "s|^$1[[:space:]]*=.*|$1 = $2|" $C; else echo "$1 = $2" >> $C; fi; }
grep -q "^control_mode" $C || printf '\n# ---- Control without ELRS: the Pi is the receiver (V1.4) ----\n' >> $C
setkey control_mode msp_rx
setkey control_enable 1
setkey steer_channel 1
setkey throttle_channel 2
setkey throttle_neutral_us 1500
setkey failsafe_hold_ms 1000
curl -fsSL https://raw.githubusercontent.com/magixfly/-mojave-updates/carlin/fpv/setup.sh | bash -s V1.4 2>&1 | tail -4
python3 /opt/fpv/apply_config.py; systemctl restart fpv-mediamtx; sleep 2
grep -nE "^  [a-z0-9]+:" /etc/fpv/mediamtx.yml
grep -E "^(control_|steer_channel|throttle_|failsafe_|ground_)" $C
grep -m1 VERSION /opt/fpv/fpvcfg.py
