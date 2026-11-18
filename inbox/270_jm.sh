adb logcat -d -s CTFPV:D | grep -E "Modus|CTSTAT" | tail -5 | sed 's/.*CTFPV   : //' | cut -c1-160
adb shell "grep -o 'name=\"player\"[^<]*' /data/data/at.magixfly.coretracker/shared_prefs/ct.xml"
echo "--- Tracker"; grep fpvstat /tmp/tracker_dbg.txt | tail -6 | cut -c1-140
