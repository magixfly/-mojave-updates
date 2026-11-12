// car.h - Car mode of the ESP-NOW receiver (V1.4)
// Own Wi-Fi access point on the ESP-NOW channel + web page for the car display (CarlinKit box / any browser).
// The page gets the same CRSF frames the Pi reads over USB (WebSocket /ws, binary) and does all the logic itself.
#pragma once
#include <Arduino.h>

// start the access point + web server. ch = the ESP-NOW channel (1 = ELRS backpack). Call after WiFi/ESP-NOW init.
bool carBegin(const char* ssid, const char* pass, uint8_t ch, bool hidden, const char* ver);
void carStop();
// hand over one complete CRSF frame (sync, len, type, payload, crc) - same bytes that go to the Pi
void carFrame(const uint8_t* f, size_t n);
// call often from loop(): sends the collected frames to all browsers (every 40 ms)
void carLoop();
int carClients();        // Wi-Fi stations connected to the access point
int carWsClients();      // open web pages (WebSocket)
bool carActive();
