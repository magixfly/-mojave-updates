#pragma once
#include <Arduino.h>
// V1.5: Bluetooth LE output for the Carlin box (Nordic UART Service): same byte stream as USB (CRSF frames)
void bleBegin(const char* name);
void bleFrame(const uint8_t* d, size_t n);   // queue bytes (from loop)
void bleLoop();                              // send queued bytes as notifications
bool bleConnected();
uint32_t bleSent();
bool bleLine(String& out);                   // a command line received over BLE (config/status/set/save/reboot)
