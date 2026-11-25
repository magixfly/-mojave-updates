#screenshot
dumpsys package at.magixfly.coretracker | grep -m2 "versionName\|versionCode"
logcat -d -t 400 | grep -i "CTAP\|CTBB\|PackageInstaller\|ct_update" | tail -40
ls -la /data/local/tmp/ct_update.apk 2>&1
