#timeout 60
F=/boot/firmware/config.txt
cp -n $F $F.before-gpumem
if grep -qE "^gpu_mem=" $F; then sed -i -E "s|^gpu_mem=.*|gpu_mem=256|" $F; else printf '\n# Mojave FPV LTE: more memory for the video chip (USB camera decode + encode next to the main camera)\ngpu_mem=256\n' >> $F; fi
grep -nE "gpu_mem|dtoverlay|camera_auto" $F; vcgencmd get_mem gpu; free -m | sed -n 2p
systemd-run --quiet --on-active=6 systemctl reboot; systemd-run --quiet --on-active=80 systemctl reboot --force --force; echo "reboot in 6 s"
