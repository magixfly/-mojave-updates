// Core Tracker ESP-NOW receiver V1.4 (Waveshare ESP32-S3-Zero)
// Rewritten 12.11.2026 (source of 1.3 lost), same data to the Pi as 1.3, plus car mode (own Wi-Fi + web page).
//
// To the Pi (USB CDC and optional UART), CRSF frames:
//   telemetry of the ELRS backpacks (MSP v2 function 0x11), each preceded by 0x7D = sender MAC(6) + dBm(1)
//   0x7A every second: ESP receive dBm, packets/s, bad/s
//   0x7B Core broadcast (NaviBoden, magic 0x564E typ 20): MAC(6) + dBm(1) + packet (<= 53 bytes)
//   0x7C own GPS: lat, lon int32 1e7, alt int16 m, km/h*10, course*10, sats, fix, hdop*10 (little endian)
// Car mode (car.cpp): access point on the backpack channel, web page http://192.168.4.1 gets the same frames.
#include <Arduino.h>
#include <WiFi.h>
#include <esp_wifi.h>
#include <esp_now.h>
#include <LittleFS.h>
#include <MD5Builder.h>
#include "car.h"

#define VERSION "1.4"
#define LED_PIN 21
#define GPS_RX 5      // GPS-TX -> GP5
#define GPS_TX 6      // GPS-RX <- GP6

// ---------------------------------------------------------------- settings (config.txt in LittleFS)
struct Cfg {
  String phrase, uid;
  int channel = 1, led = 20, any_sender = 1, core = 1, core_scan = 1, core_poll = 2, gps = 1;
  long gps_baud = 0;
  int mac_tag = 1, uart = 1;
  long uart_baud = 115200;
  int uart_tx = 43, uart_rx = 44;
  int ap = 1, ap_hidden = 0, ap_scan_stop = 1;
  String ap_ssid = "CoreTracker", ap_pass = "coretracker";
} C;

static const char* CFG_PATH = "/config.txt";

static void cfgSet(const String& k, const String& v) {
  if (k == "phrase") C.phrase = v; else if (k == "uid") C.uid = v;
  else if (k == "channel") C.channel = constrain(v.toInt(), 1, 13);
  else if (k == "led") C.led = constrain(v.toInt(), 0, 255);
  else if (k == "any_sender") C.any_sender = v.toInt();
  else if (k == "core") C.core = v.toInt();
  else if (k == "core_scan") C.core_scan = v.toInt();
  else if (k == "core_poll") C.core_poll = max(1L, v.toInt());
  else if (k == "gps") C.gps = v.toInt();
  else if (k == "gps_baud") C.gps_baud = v.toInt();
  else if (k == "mac_tag") C.mac_tag = v.toInt();
  else if (k == "uart") C.uart = v.toInt();
  else if (k == "uart_baud") C.uart_baud = v.toInt();
  else if (k == "uart_tx") C.uart_tx = v.toInt();
  else if (k == "uart_rx") C.uart_rx = v.toInt();
  else if (k == "ap") C.ap = v.toInt();
  else if (k == "ap_ssid") C.ap_ssid = v;
  else if (k == "ap_pass") C.ap_pass = v;
  else if (k == "ap_hidden") C.ap_hidden = v.toInt();
  else if (k == "ap_scan_stop") C.ap_scan_stop = v.toInt();
}

static String cfgText() {
  String s;
  s.reserve(2400);
  s += "# Core Tracker ESP-NOW receiver V" VERSION " - settings (read at start, change: edit + reboot)\n";
  s += "phrase=" + C.phrase + "   # ELRS-Bindungsphrase (gleich wie Sender/Empfaenger)\n";
  s += "uid=" + C.uid + "   # leer = aus phrase berechnen; sonst 6 Bytes z.B. 12,34,56,78,9A,BC\n";
  s += "channel=" + String(C.channel) + "   # WLAN-Kanal des Backpacks (ELRS Backpack sendet auf 1)\n";
  s += "led=" + String(C.led) + "   # Helligkeit der Status-LED 0..255 (0 = aus)\n";
  s += "any_sender=" + String(C.any_sender) + "   # 1 = alle Backpack-Pakete auf dem Kanal annehmen (Mithoeren)\n";
  s += "core=" + String(C.core) + "   # 1 = Rundruf des Mojave Core (ab V2.72) an den Pi weiterreichen\n";
  s += "core_scan=" + String(C.core_scan) + "   # 1 = Core auf allen Kanaelen suchen, wenn er nicht auf channel ist\n";
  s += "core_poll=" + String(C.core_poll) + "   # s: so oft kurz zum Core-Kanal springen (nur wenn Core nicht auf channel)\n";
  s += "gps=" + String(C.gps) + "   # 1 = GPS-Modul an GP5 (GPS-TX) / GP6 (GPS-RX) benutzen\n";
  s += "gps_baud=" + String(C.gps_baud) + "   # 0 = automatisch (115200/38400/57600/9600)\n";
  s += "mac_tag=" + String(C.mac_tag) + "   # 1 = Sender-MAC vor jedem Telemetrie-Frame mitschicken (Tracker ab V2.0 ordnet Sender den Autos zu)\n";
  s += "uart=" + String(C.uart) + "   # 1 = Daten zusaetzlich ueber UART an den Pi-GPIO (ESP im Gehaeuse, ohne USB-Kabel)\n";
  s += "uart_baud=" + String(C.uart_baud) + "   # Baudrate UART (gleich wie baud= in der config.txt am Pi)\n";
  s += "uart_tx=" + String(C.uart_tx) + "   # ESP-Pin TX -> Pi Pin 10 (GPIO15 RXD); 43 = Pin \"TX\" am Zero\n";
  s += "uart_rx=" + String(C.uart_rx) + "   # ESP-Pin RX <- Pi Pin 8 (GPIO14 TXD); 44 = Pin \"RX\" am Zero\n";
  s += "ap=" + String(C.ap) + "   # 1 = eigenes WLAN fuer Auto-Display/Handy (Car-Modus, Seite http://192.168.4.1), 0 = aus\n";
  s += "ap_ssid=" + C.ap_ssid + "   # Name des WLANs\n";
  s += "ap_pass=" + C.ap_pass + "   # Passwort (mind. 8 Zeichen, kuerzer = offenes WLAN)\n";
  s += "ap_hidden=" + String(C.ap_hidden) + "   # 1 = WLAN-Name versteckt\n";
  s += "ap_scan_stop=" + String(C.ap_scan_stop) + "   # 1 = keine Core-Kanalsuche, solange ein Geraet im WLAN ist (Verbindung bleibt stabil)\n";
  return s;
}

static bool cfgSave() {
  File f = LittleFS.open(CFG_PATH, "w");
  if (!f) return false;
  f.print(cfgText());
  f.close();
  return true;
}

static void cfgLoad() {
  static const char* keys[] = {"phrase", "uid", "channel", "led", "any_sender", "core", "core_scan", "core_poll", "gps", "gps_baud",
                               "mac_tag", "uart", "uart_baud", "uart_tx", "uart_rx", "ap", "ap_ssid", "ap_pass", "ap_hidden", "ap_scan_stop"};
  bool seen[sizeof(keys) / sizeof(keys[0])] = {};
  File f = LittleFS.open(CFG_PATH, "r");
  if (f) {
    while (f.available()) {
      String l = f.readStringUntil('\n');
      int h = l.indexOf('#');
      if (h >= 0) l = l.substring(0, h);
      int e = l.indexOf('=');
      if (e < 1) continue;
      String k = l.substring(0, e), v = l.substring(e + 1);
      k.trim(); v.trim();
      cfgSet(k, v);
      for (size_t i = 0; i < sizeof(keys) / sizeof(keys[0]); i++) if (k == keys[i]) seen[i] = true;
    }
    f.close();
  }
  bool missing = false;
  for (bool s : seen) if (!s) missing = true;
  if (missing) cfgSave();                       // new keys (V1.4: ap...) are added with their defaults
}

// ---------------------------------------------------------------- output (USB + UART + car page)
struct Out { uint8_t n; uint8_t d[64]; };
static QueueHandle_t outQ;

static uint8_t crc8(const uint8_t* d, size_t n) {
  uint8_t c = 0;
  while (n--) { c ^= *d++; for (int i = 0; i < 8; i++) c = (c & 0x80) ? (uint8_t)((c << 1) ^ 0xD5) : (uint8_t)(c << 1); }
  return c;
}

// build a CRSF frame 0xC8 len type payload crc and queue it (safe from Wi-Fi callbacks)
static void queueFrame(uint8_t type, const uint8_t* p, uint8_t n) {
  if (n > 60) n = 60;
  Out o;
  o.d[0] = 0xC8; o.d[1] = n + 2; o.d[2] = type;
  memcpy(o.d + 3, p, n);
  o.d[3 + n] = crc8(o.d + 2, n + 1);
  o.n = n + 4;
  xQueueSend(outQ, &o, 0);
}
static void queueRaw(const uint8_t* f, uint8_t n) {
  if (n > 64) return;
  Out o; o.n = n; memcpy(o.d, f, n);
  xQueueSend(outQ, &o, 0);
}

static void writeOut(const uint8_t* d, size_t n) {
  Serial.write(d, n);                           // tx timeout 0: no host reading -> dropped, loop never blocks
  if (C.uart) Serial0.write(d, n);
  carFrame(d, n);
}

// ---------------------------------------------------------------- statistics
struct Snd { uint8_t mac[6]; int8_t rssi; uint32_t n, last; };
static Snd snd[8];
static volatile uint32_t pk = 0, pkBad = 0, pkSec = 0, badSec = 0, lastPk = 0;
static volatile int32_t rssiSum = 0, rssiN = 0;
static volatile uint32_t other = 0, coreN = 0, coreLast = 0;
static uint8_t otherMac[6], otherCh, otherB[4];
static int8_t otherRssi, coreRssi;
static volatile uint8_t coreCh = 0, curCh = 1, coreHeardCh = 0;
static volatile int8_t bestRssi[16];
static uint8_t uid[6];

static void noteSender(const uint8_t* m, int8_t r) {
  int fr = -1, old = 0;
  for (int i = 0; i < 8; i++) {
    if (snd[i].n && !memcmp(snd[i].mac, m, 6)) { snd[i].n++; snd[i].rssi = r; snd[i].last = millis(); return; }
    if (!snd[i].n && fr < 0) fr = i;
    if (snd[i].last < snd[old].last) old = i;
  }
  int i = fr >= 0 ? fr : old;
  memcpy(snd[i].mac, m, 6); snd[i].rssi = r; snd[i].n = 1; snd[i].last = millis();
}

// ---------------------------------------------------------------- one ESP-NOW packet (from promiscuous or receive callback)
static void handlePacket(const uint8_t* src, int8_t rssi, const uint8_t* d, int len) {
  // ELRS backpack: MSP v2  '$' 'X' type flag fnLo fnHi szLo szHi payload crc
  if (len >= 9 && d[0] == '$' && d[1] == 'X') {
    uint16_t fn = d[4] | (d[5] << 8), sz = d[6] | (d[7] << 8);
    if (8 + sz + 1 > len) { pkBad++; badSec++; return; }
    uint8_t c = 0;
    for (int i = 3; i < 8 + sz; i++) {          // crc8 dvb-s2 over flag..payload
      c ^= d[i];
      for (int k = 0; k < 8; k++) c = (c & 0x80) ? (uint8_t)((c << 1) ^ 0xD5) : (uint8_t)(c << 1);
    }
    if (c != d[8 + sz]) { pkBad++; badSec++; return; }
    if (fn != 0x0011 || sz < 3) return;
    const uint8_t* p = d + 8;
    pk++; pkSec++; lastPk = millis(); rssiSum += rssi; rssiN++;
    noteSender(src, rssi);
    if (C.mac_tag) { uint8_t t[7]; memcpy(t, src, 6); t[6] = (uint8_t)rssi; queueFrame(0x7D, t, 7); }
    if ((p[0] == 0xC8 || p[0] == 0xEA || p[0] == 0xEE || p[0] == 0xEC) && p[1] + 2 <= sz) queueRaw(p, p[1] + 2);
    else if (p[0] + 1 <= sz && p[0] >= 2) { uint8_t f[64]; if (p[0] + 2 > 64) return; f[0] = 0xC8; memcpy(f + 1, p, p[0] + 1); queueRaw(f, p[0] + 2); }
    return;
  }
  // Mojave Core broadcast (navi_proto.h NaviBoden): magic 0x564E little endian, typ 20
  if (len >= 4 && d[0] == 0x4E && d[1] == 0x56 && d[2] == 20) {
    coreN++; coreLast = millis(); coreRssi = rssi; coreHeardCh = curCh;
    if (rssi > bestRssi[curCh & 15]) bestRssi[curCh & 15] = rssi;   // channel search: neighbour channels are heard too -> take the strongest
    if (C.core) {
      uint8_t t[60]; memcpy(t, src, 6); t[6] = (uint8_t)rssi;
      int n = min(len, 53);
      memcpy(t + 7, d, n);
      queueFrame(0x7B, t, 7 + n);
    }
    return;
  }
  if (len >= 2 && d[0] == 0x4E && d[1] == 0x56) return;   // our own question / other Core types
  other++; memcpy(otherMac, src, 6); otherCh = curCh; otherRssi = rssi;
  for (int i = 0; i < 4; i++) otherB[i] = i < len ? d[i] : 0;
}

static void IRAM_ATTR promisc(void* buf, wifi_promiscuous_pkt_type_t type) {
  if (type != WIFI_PKT_MGMT) return;
  const wifi_promiscuous_pkt_t* pp = (const wifi_promiscuous_pkt_t*)buf;
  const uint8_t* f = pp->payload;
  int n = pp->rx_ctrl.sig_len - 4;              // without FCS
  if (n < 40 || f[0] != 0xD0) return;           // action frame
  if (f[24] != 0x7F || f[25] != 0x18 || f[26] != 0xFE || f[27] != 0x34) return;   // vendor specific, Espressif
  if (f[32] != 0xDD || f[34] != 0x18 || f[35] != 0xFE || f[36] != 0x34 || f[37] != 0x04) return;   // ESP-NOW element
  int dl = f[33] - 5;
  if (dl <= 0 || 39 + dl > n) return;
  handlePacket(f + 10, (int8_t)pp->rx_ctrl.rssi, f + 39, dl);
}

static void onRecv(const esp_now_recv_info_t* info, const uint8_t* d, int len) {
  if (C.any_sender) return;                     // promiscuous mode sees everything already
  handlePacket(info->src_addr, info->rx_ctrl ? (int8_t)info->rx_ctrl->rssi : 0, d, len);
}

// ---------------------------------------------------------------- Core search on other channels
static const uint8_t BCAST[6] = {0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF};
static const uint8_t ASK[4] = {0x4E, 0x56, 21, 1};
enum { CS_IDLE, CS_SCAN, CS_POLL };
static int csState = CS_IDLE, csCh = 0, csFail = 0;
static uint32_t csT = 0, csNextScan = 0, csNextPoll = 0;

static uint32_t chErr = 0, polls = 0, pollOk = 0, scans = 0;
static int chErrLast = 0, chErrCh = 0;
static void setCh(uint8_t ch) {
  if (curCh == ch) return;
  esp_err_t e = esp_wifi_set_channel(ch, WIFI_SECOND_CHAN_NONE);
  if (e == ESP_OK) curCh = ch; else { chErr++; chErrLast = e; chErrCh = ch; }
}
#define CS_WAIT 200   // ms on a foreign channel waiting for the Core (it may answer only at its next beacon)

static bool scanAllowed() {
  if (!C.core || !C.core_scan) return false;
  if (C.ap && C.ap_scan_stop && carClients() > 0) return false;   // car display connected -> stay on the channel
  return true;
}

static void coreSearch() {
  uint32_t now = millis();
  bool fresh = coreLast && now - coreLast < 6000;
  switch (csState) {
    case CS_IDLE:
      if (!scanAllowed()) return;
      if (fresh && coreHeardCh == C.channel) { coreCh = C.channel; return; }   // Core is on our channel, nothing to do
      if (!fresh && coreCh == C.channel) coreCh = 0;         // Core left our channel -> search again
      if (coreCh && coreCh != C.channel && now >= csNextPoll) {          // known channel: short visit
        csState = CS_POLL; csCh = coreCh; csT = now; polls++; setCh(csCh); esp_now_send(BCAST, ASK, sizeof(ASK));
        return;
      }
      if (!coreCh && !fresh && now >= csNextScan) { csState = CS_SCAN; csCh = 0; csT = 0; scans++; }
      return;
    case CS_POLL:
      if (coreLast >= csT && coreLast) { pollOk++; csFail = 0; setCh(C.channel); csState = CS_IDLE; csNextPoll = now + C.core_poll * 1000; return; }
      if (now - csT >= CS_WAIT) {
        setCh(C.channel); csState = CS_IDLE; csNextPoll = now + C.core_poll * 1000;
        if (++csFail >= 3) { csFail = 0; coreCh = 0; csNextScan = now; }
      }
      return;
    case CS_SCAN:                                            // full sweep, the channel with the strongest Core signal wins
      if (csT && now - csT < CS_WAIT) return;
      if (!csT) for (int i = 0; i < 16; i++) bestRssi[i] = -128;
      do csCh++; while (csCh == C.channel);
      if (csCh > 13) {
        int b = 0;
        for (int i = 1; i <= 13; i++) if (bestRssi[i] > -128 && (!b || bestRssi[i] > bestRssi[b])) b = i;
        setCh(C.channel); csState = CS_IDLE; csFail = 0;
        if (b) { coreCh = b; csNextPoll = now + C.core_poll * 1000; } else csNextScan = now + 15000;
        return;
      }
      setCh(csCh); csT = now; esp_now_send(BCAST, ASK, sizeof(ASK));
      return;
  }
}

// ---------------------------------------------------------------- GPS (NMEA GGA/RMC, automatic baud rate)
static HardwareSerial& GPS = Serial1;
static const long BAUDS[] = {115200, 38400, 57600, 9600};
static int gBaudI = 0;
static long gBaud = 0;
static uint32_t gTry = 0, gLastOk = 0, gLastOut = 0;
static char gl[100];
static int gn = 0;
static struct { int32_t lat = 0, lon = 0; int16_t alt = 0; uint16_t kmh = 0, crs = 0; uint8_t sats = 0, fix = 0, hd = 0; } G;

static void ubx(const uint8_t* m, size_t n) {
  uint8_t a = 0, b = 0;
  for (size_t i = 2; i < n; i++) { a += m[i]; b += a; }
  GPS.write(m, n); GPS.write(a); GPS.write(b);
}
static void gpsRate5Hz() {
  const uint8_t legacy[] = {0xB5, 0x62, 0x06, 0x08, 6, 0, 200, 0, 1, 0, 1, 0};           // CFG-RATE 200 ms
  const uint8_t valset[] = {0xB5, 0x62, 0x06, 0x8A, 10, 0, 0, 1, 0, 0, 0x01, 0x00, 0x21, 0x30, 200, 0};   // CFG-RATE-MEAS, RAM
  ubx(legacy, sizeof(legacy));
  ubx(valset, sizeof(valset));
}
static int32_t nmeaDeg(const char* s, const char* hemi) {
  if (!*s) return 0;
  double v = atof(s);
  int deg = (int)(v / 100);
  double d = deg + (v - deg * 100) / 60.0;
  if (*hemi == 'S' || *hemi == 'W') d = -d;
  return (int32_t)lround(d * 1e7);
}
static void gpsOut() {
  uint8_t p[17];
  memcpy(p, &G.lat, 4); memcpy(p + 4, &G.lon, 4); memcpy(p + 8, &G.alt, 2);
  memcpy(p + 10, &G.kmh, 2); memcpy(p + 12, &G.crs, 2);
  p[14] = G.sats; p[15] = G.fix; p[16] = G.hd;
  queueFrame(0x7C, p, 17);
}
static void nmeaLine(char* l) {
  char* star = strchr(l, '*');
  if (l[0] != '$' || !star) return;
  uint8_t c = 0;
  for (char* q = l + 1; q < star; q++) c ^= *q;
  if (strtol(star + 1, nullptr, 16) != c) return;
  *star = 0;
  gLastOk = millis();
  char* f[20]; int n = 0;
  for (char* q = l; n < 20; ) { f[n++] = q; char* k = strchr(q, ','); if (!k) break; *k = 0; q = k + 1; }
  const char* t = f[0] + 3;
  if (!strcmp(t, "GGA") && n >= 10) {
    G.fix = atoi(f[6]) > 0; G.sats = atoi(f[7]); G.hd = (uint8_t)min(255.0, atof(f[8]) * 10); G.alt = (int16_t)lround(atof(f[9]));
  } else if (!strcmp(t, "RMC") && n >= 9) {
    if (*f[2] == 'A') { G.lat = nmeaDeg(f[3], f[4]); G.lon = nmeaDeg(f[5], f[6]); }
    else G.fix = 0;
    G.kmh = (uint16_t)lround(atof(f[7]) * 1.852 * 10); G.crs = (uint16_t)lround(atof(f[8]) * 10);
    if (millis() - gLastOut >= 190) { gLastOut = millis(); gpsOut(); }
  }
}
static void gpsLoop() {
  if (!C.gps) return;
  uint32_t now = millis();
  bool ok = gLastOk && now - gLastOk < 5000;
  if (!ok && (!gBaud || now - gTry >= 1500)) {          // no valid NMEA: (next) baud rate
    long b = C.gps_baud ? C.gps_baud : BAUDS[gBaudI++ % 4];
    if (b != gBaud) { GPS.end(); GPS.begin(b, SERIAL_8N1, GPS_RX, GPS_TX); gBaud = b; }
    gTry = now; gn = 0; gLastOk = 0;
  }
  while (GPS.available()) {
    char ch = GPS.read();
    if (ch == '$') gn = 0;
    if (ch == '\r' || ch == '\n') {
      if (gn > 6) {
        gl[gn] = 0;
        bool first = !gLastOk;
        nmeaLine(gl);
        if (first && gLastOk) gpsRate5Hz();
      }
      gn = 0;
    } else if (gn < (int)sizeof(gl) - 1) gl[gn++] = ch;
  }
}

// ---------------------------------------------------------------- LED
static uint32_t ledFlash = 0;
static void ledLoop() {
  static uint32_t t = 0;
  uint32_t now = millis();
  if (now - t < 50) return;
  t = now;
  if (!C.led) { rgbLedWrite(LED_PIN, 0, 0, 0); return; }
  uint8_t r = 0, g = 0, b = 0;
  bool data = lastPk && now - lastPk < 3000, core = coreLast && now - coreLast < 3000;
  if (data) g = 255; else if (core) b = 255; else r = 255;
  if (carClients() > 0) { b = 255; if (!data) r = 0; }                  // car display connected: cyan / blue
  if (lastPk && now - lastPk < 60) { r = g = b = 255; }                  // flash per packet
  int k = C.led;
  rgbLedWrite(LED_PIN, r * k / 255, g * k / 255, b * k / 255);
}

// ---------------------------------------------------------------- USB commands: config, status, set k=v, save, reboot
static void printStatus(Print& o) {
  uint32_t now = millis();
  o.printf("# Core Tracker ESP-NOW receiver V%s  uid=%02X:%02X:%02X:%02X:%02X:%02X  ch=%d  any_sender=%d  packets=%lu  bad=%lu  last=%lus\n",
           VERSION, uid[0], uid[1], uid[2], uid[3], uid[4], uid[5], C.channel, C.any_sender, (unsigned long)pk, (unsigned long)pkBad,
           lastPk ? (unsigned long)((now - lastPk) / 1000) : 9999UL);
  o.printf("# core=%d packets=%lu last=%lus ch=%d rssi=%d  gps=%d baud=%ld fix=%d sats=%d  uart=%d (TX GP%d / RX GP%d, %ld baud)  mac_tag=%d\n",
           C.core, (unsigned long)coreN, coreLast ? (unsigned long)((now - coreLast) / 1000) : 9999UL, coreCh, coreRssi, C.gps, gBaud,
           G.fix, G.sats, C.uart, C.uart_tx, C.uart_rx, C.uart_baud, C.mac_tag);
  for (auto& s : snd) if (s.n)
    o.printf("# sender %02X:%02X:%02X:%02X:%02X:%02X  %d dBm  packets=%lu  last=%lus\n", s.mac[0], s.mac[1], s.mac[2], s.mac[3], s.mac[4],
             s.mac[5], s.rssi, (unsigned long)s.n, (unsigned long)((now - s.last) / 1000));
  o.printf("# other espnow=%lu last %02X:%02X:%02X:%02X:%02X:%02X ch=%d rssi=%d bytes %02X %02X %02X %02X\n", (unsigned long)other,
           otherMac[0], otherMac[1], otherMac[2], otherMac[3], otherMac[4], otherMac[5], otherCh, otherRssi, otherB[0], otherB[1], otherB[2], otherB[3]);
  o.printf("# search scans=%lu polls=%lu ok=%lu chErr=%lu (%d at ch %d) now_ch=%d state=%d csCh=%d fail=%d next_poll=%lds next_scan=%lds allowed=%d\n",
           (unsigned long)scans, (unsigned long)polls, (unsigned long)pollOk, (unsigned long)chErr, chErrLast, chErrCh, curCh, csState, csCh, csFail,
           (long)((int32_t)(csNextPoll - now) / 1000), (long)((int32_t)(csNextScan - now) / 1000), scanAllowed());
  o.printf("# car ap=%d ssid=%s active=%d stations=%d pages=%d  heap=%u\n", C.ap, C.ap_ssid.c_str(), carActive(), carClients(),
           carWsClients(), (unsigned)ESP.getFreeHeap());
}

static void command(String l) {
  l.trim();
  if (l == "config") { String t = cfgText(); Serial.print(t); }
  else if (l == "status") printStatus(Serial);
  else if (l.startsWith("set ")) {
    int e = l.indexOf('=');
    if (e > 4) { String k = l.substring(4, e), v = l.substring(e + 1); k.trim(); v.trim(); cfgSet(k, v); Serial.println("# ok (save + reboot zum Anwenden)"); }
  } else if (l == "save") Serial.println(cfgSave() ? "# gespeichert" : "# Fehler beim Speichern");
  else if (l == "reboot") { delay(100); ESP.restart(); }
  else if (l == "version") Serial.println("# V" VERSION);
  else if (l == "help") Serial.println("# commands: config, status, set name=value, save, reboot, version");
}

static void cmdLoop() {
  static String in;
  while (Serial.available()) {
    char c = Serial.read();
    if (c == '\n' || c == '\r') { if (in.length()) command(in); in = ""; }
    else if (c >= 32 && c < 127 && in.length() < 200) in += c;
    else if (c < 32 || c >= 127) in = "";      // binary garbage
  }
}

// ---------------------------------------------------------------- setup / loop
static void calcUid() {
  int b[6];
  if (C.uid.length() && sscanf(C.uid.c_str(), "%x%*[,: ]%x%*[,: ]%x%*[,: ]%x%*[,: ]%x%*[,: ]%x", &b[0], &b[1], &b[2], &b[3], &b[4], &b[5]) == 6) {
    for (int i = 0; i < 6; i++) uid[i] = b[i];
  } else {
    MD5Builder m; m.begin();
    m.add(String("-DMY_BINDING_PHRASE=\"") + C.phrase + "\"");
    m.calculate();
    uint8_t h[16]; m.getBytes(h);
    memcpy(uid, h, 6);
  }
  uid[0] &= ~0x01;                              // unicast MAC, same as the ELRS backpack
}

void setup() {
  Serial.setTxTimeoutMs(0);
  Serial.begin(115200);
  outQ = xQueueCreate(96, sizeof(Out));
  LittleFS.begin(true);
  cfgLoad();
  calcUid();
  if (C.uart) Serial0.begin(C.uart_baud, SERIAL_8N1, C.uart_rx, C.uart_tx);

  WiFi.mode(C.ap ? WIFI_AP_STA : WIFI_STA);
  esp_wifi_set_mac(WIFI_IF_STA, uid);
  WiFi.disconnect();
  esp_wifi_set_ps(WIFI_PS_NONE);
  if (C.ap) carBegin(C.ap_ssid.c_str(), C.ap_pass.c_str(), C.channel, C.ap_hidden, VERSION);
  esp_wifi_set_channel(C.channel, WIFI_SECOND_CHAN_NONE);
  curCh = C.channel;

  esp_now_init();
  esp_now_register_recv_cb(onRecv);
  esp_now_peer_info_t pi = {};
  memcpy(pi.peer_addr, BCAST, 6);
  pi.channel = 0; pi.ifidx = WIFI_IF_STA; pi.encrypt = false;
  esp_now_add_peer(&pi);

  if (C.any_sender) {
    wifi_promiscuous_filter_t flt = {.filter_mask = WIFI_PROMIS_FILTER_MASK_MGMT};
    esp_wifi_set_promiscuous_filter(&flt);
    esp_wifi_set_promiscuous_rx_cb(promisc);
    esp_wifi_set_promiscuous(true);
  }
}

void loop() {
  Out o;
  while (xQueueReceive(outQ, &o, 0) == pdTRUE) writeOut(o.d, o.n);
  static uint32_t tSec = 0;
  uint32_t now = millis();
  if (now - tSec >= 1000) {
    tSec = now;
    int32_t r = rssiN ? rssiSum / rssiN : 0;
    uint8_t p[3] = {(uint8_t)(int8_t)r, (uint8_t)(pkSec > 255 ? 255 : pkSec), (uint8_t)(badSec > 255 ? 255 : badSec)};
    rssiSum = 0; rssiN = 0; pkSec = 0; badSec = 0;
    queueFrame(0x7A, p, 3);
  }
  coreSearch();
  gpsLoop();
  carLoop();
  cmdLoop();
  ledLoop();
  delay(1);
}
