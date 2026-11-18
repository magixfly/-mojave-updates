#nobox
# Jmuxer am Tracker: 60 s nach Wahl prüfen
sleep 60; grep -E "fpvnopic|fpvstat" /tmp/tracker_dbg.txt | tail -3 | cut -c1-160
