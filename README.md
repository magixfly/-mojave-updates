# Carlin-Bridge (Branch `carlin`)

Der Pi (corepi) fragt diesen Branch jede Minute ab und steuert damit die CarlinKit-Box im Kia per ADB
(Android Debug Bridge = Fernsteuerung für Android übers WLAN).

- `inbox/NNN_name.sh` – Befehl (Bash-Script, `adb` ist verfügbar). Läuft genau einmal.
  Zeile `#screenshot` im Script → danach Bildschirmfoto der Box.
- `outbox/NNN_name.log` / `.png` – Ergebnis vom Pi
- `outbox/status.txt` – Lebenszeichen: ist die Box erreichbar?
- `apk/` – App-Dateien zum Installieren
- `config.txt` – IP/Port der Box, Intervalle

## FPV-Pi (mojave-fpv), ab FPV LTE V1.2
- `fpvin/NNN_name.sh` – Befehl für den FPV-Pi (Bash als root, läuft genau einmal, max. 600 s; Zeile `#timeout N` ändert das)
- `fpvout/NNN_name.log` – Ergebnis, `fpvout/status.txt` – Lebenszeichen alle 10 min (beides nur mit GitHub-Token am Pi)
- `fpv/setup.sh` + `fpv/fpv_pi_Vx.y.tar.gz` – Installation/Update der Pi-Software
- Token am Pi: Einstellungsseite `http://mojave-fpv:8080/settings` → „Remote maintenance“
