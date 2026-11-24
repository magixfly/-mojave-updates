#timeout 900
curl -fsSL https://raw.githubusercontent.com/magixfly/-mojave-updates/carlin/fpv/setup.sh | bash -s V1.4.1 2>&1 | tail -2
python3 /opt/fpv/apply_config.py; systemctl restart fpv-mediamtx
sleep 35
echo "--- pipelines"; journalctl -u fpv-mediamtx --since "-40s" --no-pager -o cat | grep -E "usbcam|ERR|WARN|erroneous|cam[234]\]" | tail -14 | cut -c1-200
echo "--- cpu"; top -b -n1 -w 200 | grep -E "gst-launch|ffmpeg|mediamtx" | awk '{print $9"% "$12}'
cat /run/fpv-usbcam-* 2>/dev/null; uptime; vcgencmd measure_temp
