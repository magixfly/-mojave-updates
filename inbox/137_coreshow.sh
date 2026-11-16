#screenshot
# Core-Zeile wieder einschalten (core_show war 0 = Menü "Core info: off") und Anzeigen neu laden
curl -s -X POST -H 'Content-Type: application/json' -d '{"core_show":1}' localhost:8080/api/set; echo
grep "^core_show" ~/Bodenstation/config.txt
adb -s "$T" shell am force-stop at.magixfly.coretracker; sleep 1; adb -s "$T" shell am start -n at.magixfly.coretracker/.MainActivity
export XDG_SESSION_TYPE=wayland DISPLAY=:0 WAYLAND_DISPLAY=wayland-0 XDG_RUNTIME_DIR=/run/user/1000
pkill -f "chromium.*--kiosk"; sleep 2; cd ~/Bodenstation && setsid bash ./kiosk.sh http://localhost:8080/ >/dev/null 2>&1 < /dev/null &
sleep 20; echo fertig
