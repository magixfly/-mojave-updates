#timeout 120
modprobe option && echo "option driver loaded"
echo "1286 4e31" > /sys/bus/usb-serial/drivers/option1/new_id 2>&1 && echo "id added"
sleep 3
ls -la /dev/ttyUSB* 2>&1
for t in /sys/bus/usb-serial/devices/*; do [ -e "$t" ] && echo "$(basename $t) -> $(basename $(dirname $(readlink -f $t)))"; done
cat > /tmp/at.py <<'EOF'
import os, sys, termios, time, select
dev = sys.argv[1]
try:
    fd = os.open(dev, os.O_RDWR | os.O_NOCTTY | os.O_NONBLOCK)
except OSError as e:
    print(dev, "open failed:", e); sys.exit()
a = termios.tcgetattr(fd); a[0] = 0; a[1] = 0; a[3] = 0; a[2] |= termios.CLOCAL | termios.CREAD
termios.tcsetattr(fd, termios.TCSANOW, a)
def q(c, w=1.5):
    os.write(fd, (c + "\r").encode()); buf = b""; end = time.time() + w
    while time.time() < end:
        r, _, _ = select.select([fd], [], [], 0.2)
        if r:
            try: buf += os.read(fd, 4096)
            except OSError: pass
            if b"OK\r" in buf or b"ERROR" in buf: break
    print(f"  {c!r}: {buf.decode(errors='replace').strip()!r}")
    return buf
if b"OK" not in q("AT"):
    print(dev, "no AT answer"); sys.exit()
for c in ["ATE0", "ATI", "AT+CSQ", "AT+CESQ", "AT+COPS?", "AT+CREG?", "AT+CEREG?", "AT*CESQ", "AT+CGSN=?", "AT*BANDIND?", "AT*CELLINFO?", "AT+EEMGINFO?", "AT*EEMOPT?", "AT+CPSI?", "AT^SYSINFOEX", "AT*RSRP?"]:
    q(c)
EOF
for d in /dev/ttyUSB*; do echo "=== $d"; timeout 40 python3 /tmp/at.py $d; done
echo "[100%] done"
