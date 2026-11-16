#screenshot
# Mojave wieder blau: der MT12-Backpack sendet jetzt mit MAC 46:E8:8D:5C:B4:65 (= UID aus der Bindungsphrase) -> wurde automatisch als "PLANE 2" orange angelegt
V='DA:2D:E4:3C:74:6C/1/car/1/1a8cff/MOJAVE/Thorsten;14:33:5C:8B:E2:74/2/plane/2/ff3b30/FUNJET/Thorsten;06:84:A7:E2:D3:58/2/plane/2/d4ff00/FUNJET/Horst;46:E8:8D:5C:B4:65/1/car/1/1a8cff/MOJAVE/Thorsten'
curl -s -X POST -H 'Content-Type: application/json' -d "{\"k\":\"senders\",\"v\":\"$V\"}" localhost:8080/api/cfgset; echo
grep "^senders" ~/Bodenstation/config.txt | cut -c1-260
# Anzeigen neu laden - Kiosk über systemd starten, damit er die Sperre der Fernsteuerung NICHT erbt
adb -s "$T" shell am force-stop at.magixfly.coretracker; sleep 1; adb -s "$T" shell am start -n at.magixfly.coretracker/.MainActivity
export XDG_SESSION_TYPE=wayland DISPLAY=:0 WAYLAND_DISPLAY=wayland-0 XDG_RUNTIME_DIR=/run/user/1000
pkill -f "chromium.*--kiosk"; sleep 2
systemd-run --user --collect --setenv=XDG_SESSION_TYPE=wayland --setenv=DISPLAY=:0 --setenv=WAYLAND_DISPLAY=wayland-0 --setenv=XDG_RUNTIME_DIR=/run/user/1000 --working-directory=$HOME/Bodenstation bash ./kiosk.sh http://localhost:8080/
sleep 20; echo fertig
