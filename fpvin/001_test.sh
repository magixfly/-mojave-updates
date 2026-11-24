echo "user: $(id -un)"; uname -srm; grep PRETTY /etc/os-release
echo "--- camera"; rpicam-hello --list-cameras 2>&1 | head -6
echo "--- tailscale"; tailscale status 2>&1 | head -8
echo "--- config"; grep -E '^(video_|audio_enable|cam2_enable)' /boot/firmware/fpv-config.txt
echo "--- memory / disk"; free -m | head -2; df -h / | tail -1
echo "--- mediamtx"; /opt/fpv/mediamtx --version 2>&1 | head -1; journalctl -u fpv-mediamtx -n 6 --no-pager -o cat
