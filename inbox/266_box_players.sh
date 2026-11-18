# Box: jeden FPV-Player 2,5 min messen (Janus lief schon), Ergebnis = letzte CTSTAT-Zeile
adb shell id | head -c 60; echo
F=/data/data/at.magixfly.coretracker/shared_prefs/ct.xml
adb shell "grep -o '<string name=\"player\">[0-9]</string>' $F"
adb shell input keyevent 4
for P in 2 0 1; do
  adb shell am force-stop at.magixfly.coretracker
  adb shell "if grep -q 'name=\"player\"' $F; then sed -i 's#<string name=\"player\">[0-9]</string>#<string name=\"player\">$P</string>#' $F; else sed -i 's#</map>#    <string name=\"player\">$P</string>\n</map>#' $F; fi"
  adb logcat -c; adb shell am start -n at.magixfly.coretracker/.MainActivity >/dev/null 2>&1
  sleep 165
  echo "== Player $P"; adb logcat -d -s CTFPV:D | grep -E "CTSTAT|Modus" | tail -2 | sed 's/.*CTFPV   : //'
done
#screenshot
