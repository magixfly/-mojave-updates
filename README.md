# Mojave Core – Online-Updates

Der Core (ESP32-S3 im Arrma Mojave) holt sich hier Firmware und SD-Dateien selbst:
Core-Webseite → Reiter **System** → **Online-Update** → „Nach Updates suchen“ → „Jetzt aktualisieren“.

- `manifest.json` – Inhaltsliste: Firmware-Version, Dateien mit Größe und MD5-Prüfsumme
- `firmware/` – Firmware-Dateien (`Core_V…bin`)
- `sd/` – Dateien, die 1:1 auf die SD-Karte kommen (`sd/player.html.gz` → `/player.html.gz`)
- `tools/manifest.py` – erzeugt `manifest.json` neu

Der Core lädt nur Dateien, deren Prüfsumme anders ist als auf der SD. Die Firmware nur, wenn die Version anders ist.
