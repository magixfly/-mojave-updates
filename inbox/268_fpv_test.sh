# FPV-Test: Funkweg (Ping) Tracker/Box -> CosmoStreamer über WLAN- und LAN-Adresse, dann Box-Player je 60 s
W=192.168.178.159; L=192.168.178.175
echo "== Ping Tracker (5 GHz) -> Cosmo"; for h in $W $L; do printf "%s: " $h; ping -q -c 300 -i 0.02 -s 1300 -W 1 $h | tail -2 | tr '\n' ' '; echo; done
echo "== Ping Box (2,4 GHz) -> Cosmo"; for h in $W $L; do printf "%s: " $h; adb shell "ping -q -c 300 -i 0.02 -s 1300 -W 1 $h" | tail -2 | tr '\n' ' '; echo; done
F=/data/data/at.magixfly.coretracker/shared_prefs/ct.xml
adb shell "grep -c . $F; grep -o 'name=\"player\"[^<]*' $F"
for P in 1 2 0; do
  adb shell am force-stop at.magixfly.coretracker
  adb shell "if grep -q 'name=\"player\"' $F; then sed -i 's#<string name=\"player\">[0-9]</string>#<string name=\"player\">$P</string>#' $F; else sed -i 's#</map>#    <string name=\"player\">$P</string>\n</map>#' $F; fi"
  adb logcat -c; adb shell am start -n at.magixfly.coretracker/.MainActivity >/dev/null 2>&1
  sleep 85
  echo "== Box Player $P"; adb logcat -d -s CTFPV:D | grep -E "CTSTAT|Modus|FPVSTATE" | tail -2 | sed 's/.*CTFPV   : //' | cut -c1-200
done
#screenshot
