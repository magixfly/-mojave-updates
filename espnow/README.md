# Core Tracker ESP-NOW receiver – V1.4

Waveshare ESP32-S3-Zero, pioarduino 55.03.30 (Arduino-ESP32 3.3.0), partitions default 4 MB (LittleFS at 0x290000 keeps config.txt).

- `src/main.cpp`: receiver (rewritten 12.11.2026, same output as 1.3): ELRS backpack telemetry (MSP v2 0x11) with 0x7D sender mark, 0x7A stats, 0x7B Core broadcast + channel search, 0x7C own GPS, USB + UART output, config.txt, USB commands `config`, `status`, `set k=v`, `save`, `reboot`.
- `src/car.*`: car mode – own Wi-Fi `CoreTracker` on the backpack channel, page http://192.168.4.1, WebSocket `/ws` with the same CRSF frames.
- `web/car.html`: car display page (open the file directly = demo). `tools/mkpage.py` -> `src/car_page.h`.
- `firmware/ESPNOW_V1.4_KOMPLETT_ab_0x0.bin`: flash at 0x0 (does not touch config.txt).

Binding phrase / UID are not in this repo – only in config.txt on the ESP.
