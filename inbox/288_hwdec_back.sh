#nobox
# Kiosk wieder wie vorher (Hardware-Flags brachten nichts), Kiosk neu starten
cd ~/Bodenstation && cp kiosk.sh.v309 kiosk.sh && grep -c "enable-features" kiosk.sh
export XDG_RUNTIME_DIR=/run/user/$(id -u)
pkill -f "chromium.*--kiosk"; sleep 3
systemd-run --user --collect -p KillMode=process bash -c "cd ~/Bodenstation && exec bash ./kiosk.sh > /tmp/kiosk.log 2>&1"
sleep 12; tail -1 /tmp/kiosk.log
