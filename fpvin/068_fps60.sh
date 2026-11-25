#timeout 150
Y=/etc/fpv/mediamtx.yml; cp $Y /tmp/mtx.fps.bak
S=/dev/v4l-subdev0
cnt() { timeout 12 ffmpeg -hide_banner -nostats -rtsp_transport tcp -i rtsp://localhost:8554/cam -t 5 -c copy -f null - 2>&1 | grep -oE "[0-9]{3,4}x[0-9]{3,4}|frame= *[0-9]+|video:[0-9]+KiB" | tr '\n' ' '; echo "| vblank $(v4l2-ctl -d $S --get-ctrl vertical_blanking 2>/dev/null | cut -d' ' -f2) | cpu mtxrpicam $(top -bn1 | awk '/mtxrpic/{print $9}' | head -1)"; }
grep -n "rpiCameraLevel\|rpiCameraProfile\|rpiCameraMode" $Y | tr -s ' ' | tr '\n' ';'; echo
echo "now 1080p30:      $(cnt)"
sed -i -E '0,/rpiCameraFPS:/s/(rpiCameraFPS: ).*/\160/; 0,/rpiCameraIDRPeriod:/s/(rpiCameraIDRPeriod: ).*/\160/' $Y; sleep 4
echo "1080p asked 60:   $(cnt)"
journalctl -u fpv-mediamtx --since "-12s" --no-pager -o cat | grep -iE "err|warn|level|fps|unable|fail" | tail -4 | cut -c1-170
grep -q "rpiCameraLevel" $Y && sed -i -E "0,/rpiCameraLevel:/s/(rpiCameraLevel: ).*/\1'4.2'/" $Y || sed -i -E "0,/rpiCameraFPS:/s/^( *)(rpiCameraFPS: .*)/\1\2\n\1rpiCameraLevel: '4.2'/" $Y; sleep 5
echo "1080p60 level 4.2: $(cnt)"
journalctl -u fpv-mediamtx --since "-12s" --no-pager -o cat | grep -iE "err|warn|level|unable|fail" | tail -3 | cut -c1-170
sed -i -E '0,/rpiCameraWidth:/s/(rpiCameraWidth: ).*/\11280/; 0,/rpiCameraHeight:/s/(rpiCameraHeight: ).*/\1720/' $Y; sleep 6
echo "720p asked 60:    $(cnt)"
journalctl -u fpv-mediamtx --since "-12s" --no-pager -o cat | grep -iE "err|warn|unable|fail|sensor|mode" | tail -4 | cut -c1-170
cp /tmp/mtx.fps.bak $Y; sleep 6; echo "restored:         $(cnt)"; vcgencmd measure_temp
