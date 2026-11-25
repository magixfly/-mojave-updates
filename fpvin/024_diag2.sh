#timeout 90
uptime; grep -m1 VERSION /opt/fpv/fpvcfg.py
echo "--- usb"; lsusb; ls /dev/v4l/by-id/ 2>&1
echo "--- kernel usb"; dmesg | grep -iE "usb 1-1\.|uvc|over-current|voltage" | tail -12 | cut -c1-170
echo "--- paths"; grep -nE "^  [a-z0-9]+:|usbcam" /etc/fpv/mediamtx.yml | cut -c1-170; ls -la /run/fpv-usbcam-* 2>&1 | tail -2
echo "--- video server"; journalctl -u fpv-mediamtx -b --no-pager -o cat | grep -E "cam2|usbcam|ERR|WAR|erroneous" | tail -14 | cut -c1-210
echo "--- setup log"; journalctl -u fpv-setup -b --no-pager -o cat | tail -5 | cut -c1-200
echo "--- read test"; n=$(timeout 16 ffprobe -v error -rtsp_transport tcp -count_packets -select_streams v:0 -show_entries stream=nb_read_packets -of csv=p=0 -read_intervals "%+6" rtsp://localhost:8554/cam2 2>&1 | tail -1); echo "USB camera: $n pictures in 6 s (180 expected)"
journalctl -u fpv-mediamtx --since "-18s" --no-pager -o cat | grep -E "cam2|usbcam|ERR|WAR" | tail -8 | cut -c1-210
pgrep -a "gst|ffmpeg" | cut -c1-90; vcgencmd get_mem gpu; vcgencmd get_throttled
