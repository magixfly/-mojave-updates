#!/system/bin/sh
# Core Tracker on the box: keeps server.py running (restart after an update or a crash).
D=/data/local/tmp/ct
cd $D || exit 1
export PYTHONHOME=$D/python SSL_CERT_FILE=$D/ca.pem PYTHONDONTWRITEBYTECODE=1 HOME=$D
while true; do
  echo "=== start $(date)" >> $D/run.log
  $D/ld-musl $D/python/bin/python3.13 -u $D/boxmain.py >> $D/bodenstation/server.log 2>&1
  echo "=== exit $? $(date)" >> $D/run.log
  tail -c 2000000 $D/bodenstation/server.log > $D/sl.tmp && mv $D/sl.tmp $D/bodenstation/server.log
  sleep 3
done
