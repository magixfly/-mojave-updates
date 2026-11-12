# Carlin-Bridge (Branch `carlin`)

Der Pi (corepi) fragt diesen Branch jede Minute ab und steuert damit die CarlinKit-Box im Kia per ADB
(Android Debug Bridge = Fernsteuerung für Android übers WLAN).

- `inbox/NNN_name.sh` – Befehl (Bash-Script, `adb` ist verfügbar). Läuft genau einmal.
  Zeile `#screenshot` im Script → danach Bildschirmfoto der Box.
- `outbox/NNN_name.log` / `.png` – Ergebnis vom Pi
- `outbox/status.txt` – Lebenszeichen: ist die Box erreichbar?
- `apk/` – App-Dateien zum Installieren
- `config.txt` – IP/Port der Box, Intervalle
