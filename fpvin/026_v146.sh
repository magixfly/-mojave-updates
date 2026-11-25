#timeout 90
T=$(mktemp -d); curl -fsSL https://raw.githubusercontent.com/magixfly/-mojave-updates/carlin/fpv/fpv_pi_V1.4.6.tar.gz -o $T/p.tgz && tar -xzf $T/p.tgz -C $T
cp $T/pi/*.py $T/pi/usbcam.sh /opt/fpv/ && rm -rf /opt/fpv/cockpit && cp -r $T/pi/cockpit /opt/fpv/ && cp -r $T/pi/. /boot/firmware/pi/
systemctl restart fpv-bridge; grep -m1 VERSION /opt/fpv/fpvcfg.py
echo "--- sound path"; sed -n '/^  live:/,/^  cam2:/p' /etc/fpv/mediamtx.yml | cut -c1-200
journalctl -u fpv-mediamtx --since "-3min" --no-pager -o cat | grep -E "path live|live\]|Opus|alsa|ERROR|WARNING" | tail -8 | cut -c1-200
echo "--- microphone"; arecord -l | grep -E "^card"; amixer -c C960 2>/dev/null | grep -E "Simple|Capture|\[" | head -8
echo "--- level test (3 s)"; timeout 6 arecord -D plughw:CARD=C960,DEV=0 -f S16_LE -r 48000 -c 1 -d 3 /tmp/a.wav 2>&1 | tail -1; python3 - <<'PY'
import wave, struct
try:
    w = wave.open("/tmp/a.wav"); d = w.readframes(w.getnframes()); n = len(d) // 2
    s = struct.unpack("<%dh" % n, d[:n * 2]); print("samples", n, "peak", max(abs(x) for x in s) if s else 0, "of 32767")
except Exception as e: print("no recording:", e)
PY
