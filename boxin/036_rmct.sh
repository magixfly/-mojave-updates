pgrep -f boxmai[n].py && echo "Box-Tracker laeuft noch - nicht geloescht" && exit 1
du -sh /data/local/tmp/ct
rm -rf /data/local/tmp/ct /data/local/tmp/ct_update.apk
ls -d /data/local/tmp/ct 2>/dev/null || echo "/data/local/tmp/ct geloescht"
df -h /data | tail -1
