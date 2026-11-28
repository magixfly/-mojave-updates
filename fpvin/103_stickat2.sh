#timeout 120
for d in /dev/ttyUSB1 /dev/ttyUSB2; do
  [ -e $d ] || { echo "$d gone - stop"; break; }
  echo "=== $d"; timeout 40 python3 /tmp/at.py $d
  sleep 3
done
ls /dev/ttyUSB* 2>&1; dmesg | grep -E "WUKONG|disconnect" | tail -4
echo "[100%] done"
