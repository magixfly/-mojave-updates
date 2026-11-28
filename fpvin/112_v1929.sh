#timeout 240
B=/var/lib/fpv-backup-v1928; rm -rf $B; mkdir -p $B && cp -a /opt/fpv/. $B/opt && cp -a /etc/fpv/mediamtx.yml $B/ 2>/dev/null
T=$(mktemp -d); curl -fsSL https://raw.githubusercontent.com/magixfly/-mojave-updates/carlin/fpv/fpv_pi_V1.9.29.tar.gz -o $T/p.tgz && tar -xzf $T/p.tgz -C $T 2>/dev/null
cp $T/pi/*.py $T/pi/usbcam.sh /opt/fpv/ && rm -rf /opt/fpv/cockpit && cp -r $T/pi/cockpit /opt/fpv/ && cp -r $T/pi/. /boot/firmware/pi/
python3 /opt/fpv/apply_config.py 2>&1 | tail -3
echo "--- new cam path ---"; sed -n '/^  cam:/,/^  [a-z0-9]*:$/p' /etc/fpv/mediamtx.yml | head -14
systemctl restart fpv-mediamtx fpv-bridge; sleep 12
N=$(timeout 20 ffprobe -v error -rtsp_transport tcp -select_streams v -count_packets -read_intervals "%+5" -show_entries stream=nb_read_packets -of csv=p=0 rtsp://127.0.0.1:8554/cam 2>/dev/null)
echo "frames in 5 s: $N"
if [ -z "$N" ] || [ "$N" -lt 100 ]; then
  echo "!!! video not ok - going back to V1.9.28"; journalctl -u fpv-mediamtx -n 15 --no-pager | cut -c1-180
  cp -a $B/opt/. /opt/fpv/ && cp -a $B/mediamtx.yml /etc/fpv/ && systemctl restart fpv-mediamtx fpv-bridge; sleep 8
fi
grep -m1 VERSION /opt/fpv/fpvcfg.py; systemctl is-active fpv-bridge fpv-mediamtx fpv-stickpage
curl -s -m 5 -o /dev/null -w "cockpit: http %{http_code}\n" http://localhost:8080/
curl -s -m 5 http://localhost:8080/api/latency; echo
sleep 6; echo "lte: $(curl -s -m 5 http://localhost:8080/api/lte | python3 -c 'import sys,json;d=json.load(sys.stdin);print(d.get("state"),d.get("dbm"),d.get("band"))')"
systemd-run --on-active=20 --unit=fpv-remote-restart-112 systemctl restart fpv-remote >/dev/null 2>&1 && echo "remote restart scheduled"
echo "[100%] done"
