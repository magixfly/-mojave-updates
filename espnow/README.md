# ESP-NOW receiver (Core Tracker) – firmware sources

Waveshare ESP32-S3-Zero, pioarduino 55.03.30 (Arduino-ESP32 3.3.0).

## car/ – Car mode (V1.4, in progress)
- `src/car.h`, `src/car.cpp`: own Wi-Fi access point on the ESP-NOW channel (1), web server, WebSocket `/ws` with the raw CRSF frames that also go to the Pi over USB.
- `web/car.html`: car display page (CarlinKit box / any browser): map, vehicles, battery, link, rides (GPX), all logic in the browser. Open the file directly = demo mode.
- `tools/mkpage.py`: web/car.html -> src/car_page.h (gzip).
- Still to do: merge into the receiver source 1.3 (main.cpp, not in this repo yet).

Binding phrase and UID are NOT in this repo – they live only in config.txt on the ESP.
