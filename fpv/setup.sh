#!/bin/bash
# Mojave FPV LTE - install or update the Pi software from GitHub.
# First time (on the Pi):  curl -fsSL https://raw.githubusercontent.com/magixfly/-mojave-updates/carlin/fpv/setup.sh | sudo bash
# Later updates come through the remote maintenance (fpvin/NNN_name.sh):  ... | bash -s V1.3
set -e
VER="${1:-V1.8.10}"
BASE="https://raw.githubusercontent.com/magixfly/-mojave-updates/carlin/fpv"
if [ "$(id -u)" != "0" ]; then echo "Please run with sudo"; exit 1; fi
T=$(mktemp -d)
echo "[ 5%] downloading Mojave FPV LTE $VER"
curl -fsSL "$BASE/fpv_pi_$VER.tar.gz" -o "$T/pi.tar.gz"
tar -xzf "$T/pi.tar.gz" -C "$T"
bash "$T/pi/install.sh"
mkdir -p /boot/firmware/pi && cp -r "$T/pi/." /boot/firmware/pi/ 2>/dev/null || true
echo "restarting the bridge and the remote maintenance in 3 seconds"
systemd-run --quiet --on-active=3 systemctl restart fpv-bridge fpv-remote
echo "DONE: Mojave FPV LTE $VER installed"
