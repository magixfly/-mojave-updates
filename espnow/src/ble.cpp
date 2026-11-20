#include "ble.h"
#include <BLEDevice.h>
#include <BLEServer.h>
#include <BLE2902.h>
// Nordic UART Service - the box app subscribes to TX notifications
#define NUS_SVC "6E400001-B5A3-F393-E0A9-E50E24DCCA9E"
#define NUS_RX  "6E400002-B5A3-F393-E0A9-E50E24DCCA9E"   // write: commands
#define NUS_TX  "6E400003-B5A3-F393-E0A9-E50E24DCCA9E"   // notify: CRSF stream
static BLECharacteristic* tx = nullptr;
static volatile bool conn = false;
static uint8_t ring[4096];
static size_t rHead = 0, rTail = 0;
static uint32_t sent = 0;
static uint16_t mtu = 183;   // the box app asks for MTU 247 -> 180-byte notifications
static String rxBuf, rxLine;
static volatile bool rxReady = false;

class SrvCb : public BLEServerCallbacks {
  void onConnect(BLEServer* s) override { conn = true; }
  void onDisconnect(BLEServer* s) override { conn = false; rHead = rTail = 0; BLEDevice::startAdvertising(); }
};
class RxCb : public BLECharacteristicCallbacks {
  void onWrite(BLECharacteristic* c) override {
    String v = c->getValue();
    for (size_t i = 0; i < v.length(); i++) {
      char ch = v[i];
      if (ch == '\n' || ch == '\r') { if (rxBuf.length() && !rxReady) { rxLine = rxBuf; rxReady = true; } rxBuf = ""; }
      else if (ch >= 32 && ch < 127 && rxBuf.length() < 200) rxBuf += ch;
    }
  }
};

void bleBegin(const char* name) {
  BLEDevice::init(name);
  BLEDevice::setMTU(247);
  BLEServer* s = BLEDevice::createServer();
  s->setCallbacks(new SrvCb());
  BLEService* svc = s->createService(NUS_SVC);
  tx = svc->createCharacteristic(NUS_TX, BLECharacteristic::PROPERTY_NOTIFY);
  tx->addDescriptor(new BLE2902());
  BLECharacteristic* rx = svc->createCharacteristic(NUS_RX, BLECharacteristic::PROPERTY_WRITE | BLECharacteristic::PROPERTY_WRITE_NR);
  rx->setCallbacks(new RxCb());
  svc->start();
  BLEAdvertising* a = BLEDevice::getAdvertising();
  a->addServiceUUID(NUS_SVC);
  a->setScanResponse(true);
  BLEDevice::startAdvertising();
}

void bleFrame(const uint8_t* d, size_t n) {
  if (!conn) return;
  for (size_t i = 0; i < n; i++) {
    size_t nx = (rHead + 1) % sizeof(ring);
    if (nx == rTail) return;                 // full -> drop (never block)
    ring[rHead] = d[i]; rHead = nx;
  }
}

void bleLoop() {
  static uint32_t t = 0;
  if (!conn || !tx || rHead == rTail) return;
  uint32_t now = millis();
  if (now - t < 12) return;                  // ~80 notifications/s max
  t = now;
  uint8_t buf[244];
  size_t lim = mtu > 3 ? min((size_t)(mtu - 3), sizeof(buf)) : 20, n = 0;
  while (rTail != rHead && n < lim) { buf[n++] = ring[rTail]; rTail = (rTail + 1) % sizeof(ring); }
  tx->setValue(buf, n);
  tx->notify();
  sent += n;
}

bool bleConnected() { return conn; }
uint32_t bleSent() { return sent; }
bool bleLine(String& out) { if (!rxReady) return false; out = rxLine; rxReady = false; return true; }
