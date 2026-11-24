package at.magixfly.coretracker;

import android.bluetooth.*;
import android.bluetooth.le.*;
import android.content.Context;
import java.util.UUID;

/**
 * V2.06: ESP-NOW-Empfänger des Trackers (Firmware V1.5) über Bluetooth LE (Nordic UART). Die App wertet die
 * CRSF-Daten selbst aus (wie server.py am Pi): MT12-Telemetrie des Mojave (0x02 GPS, 0x08 Akku, 0x14 Link, 0x21 Modus),
 * 0x7D Absender-MAC, 0x7A Empfangsqualität, 0x7C eigenes GPS des ESP (= Position der Box).
 */
class BleEsp {
    static final UUID NUS = UUID.fromString("6e400001-b5a3-f393-e0a9-e50e24dcca9e");
    static final UUID RX = UUID.fromString("6e400002-b5a3-f393-e0a9-e50e24dcca9e");   // zum ESP
    static final UUID TX = UUID.fromString("6e400003-b5a3-f393-e0a9-e50e24dcca9e");   // vom ESP
    static final UUID CCC = UUID.fromString("00002902-0000-1000-8000-00805f9b34fb");
    static final String NAME = "CoreTracker-ESP";

    static volatile String state = "off";
    static volatile String devName = "";
    static volatile long lastData = 0, frames = 0;
    static BleEsp me;

    final MainActivity a;
    BluetoothAdapter ad;
    volatile BluetoothGatt gatt;
    volatile boolean scanning = false;

    // Telemetrie des Mojave
    static volatile double lat, lon, kmh, hdg, volt, amp, alt;
    static volatile int sats, mah, pct = -1, lq = -1, rssi = 0, espRssi = 0, espPps = 0;
    static volatile String mode = "";
    static volatile long tGps = 0, tBat = 0, tLink = 0;
    // eigenes GPS des ESP
    static volatile double meLat, meLon, meKmh, meCrs; static volatile int meSats, meFix; static volatile long tMe = 0;
    String mac = "";        // Absender des folgenden Telemetrie-Rahmens
    String carMac = "";

    static synchronized void start(MainActivity a) {
        if (me != null || !a.prefs.getBoolean("ble", true)) return;
        me = new BleEsp(a);
        new Thread(new Runnable() { public void run() { me.loop(); } }).start();
    }

    BleEsp(MainActivity a) { this.a = a; carMac = a.prefs.getString("mojave_mac", "46:E8:8D:5C:B4:65").toUpperCase(); }

    void loop() {
        try {   // Laufzeit-Berechtigungen holt sich die App über die Root-Shell
            HotspotBoot.shell("pm grant at.magixfly.coretracker android.permission.BLUETOOTH_SCAN; pm grant at.magixfly.coretracker android.permission.BLUETOOTH_CONNECT; pm grant at.magixfly.coretracker android.permission.ACCESS_FINE_LOCATION; svc bluetooth enable");
        } catch (Throwable t) { android.util.Log.d("CTBLE", "grant: " + t); }
        BluetoothManager bm = (BluetoothManager) a.getSystemService(Context.BLUETOOTH_SERVICE);
        ad = bm == null ? null : bm.getAdapter();
        while (true) {
            try {
                if (ad == null) state = "no Bluetooth";
                else if (!ad.isEnabled()) state = "Bluetooth off";
                else if (gatt == null && !scanning) scan();
                else if (gatt != null && "connected".equals(state) && System.currentTimeMillis() - lastData > 15000) {   // verbunden, aber nichts kommt -> neu verbinden
                    android.util.Log.d("CTBLE", "no data 15 s - reconnect");
                    try { gatt.disconnect(); gatt.close(); } catch (Throwable t) { }
                    gatt = null; state = "lost";
                }
            } catch (Throwable t) { state = "error " + t.getMessage(); }
            a.js("window.ctEsp&&ctEsp(" + Client.q(state) + "," + Client.q(devName) + "," + (lastData > 0 ? (System.currentTimeMillis() - lastData) / 1000 : -1) + "," + espRssi + "," + espPps + ")");
            sleep(2000);
        }
    }

    static void sleep(long ms) { try { Thread.sleep(ms); } catch (Throwable t) { } }

    final ScanCallback cb = new ScanCallback() {
        public void onScanResult(int type, ScanResult r) {
            BluetoothDevice d = r.getDevice();
            String n = r.getScanRecord() != null ? r.getScanRecord().getDeviceName() : null;
            if (n == null || !n.startsWith(NAME) || gatt != null) return;
            devName = n;
            stopScan();
            state = "connecting";
            gatt = d.connectGatt(a, false, gcb, BluetoothDevice.TRANSPORT_LE);
        }
    };

    void scan() {
        BluetoothLeScanner sc = ad.getBluetoothLeScanner();
        if (sc == null) return;
        scanning = true;
        state = "searching";
        sc.startScan(null, new ScanSettings.Builder().setScanMode(ScanSettings.SCAN_MODE_LOW_LATENCY).build(), cb);
        new Thread(new Runnable() { public void run() { sleep(15000); if (scanning) { stopScan(); if (gatt == null) state = "not found"; } } }).start();
    }

    void stopScan() {
        scanning = false;
        try { ad.getBluetoothLeScanner().stopScan(cb); } catch (Throwable t) { }
    }

    final BluetoothGattCallback gcb = new BluetoothGattCallback() {
        public void onConnectionStateChange(BluetoothGatt g, int status, int st) {
            if (st == BluetoothProfile.STATE_CONNECTED) {
                g.requestConnectionPriority(BluetoothGatt.CONNECTION_PRIORITY_HIGH);
                g.requestMtu(247);   // ESP schickt bis 180 Bytes je Meldung
            } else {
                state = "lost";
                try { g.close(); } catch (Throwable t) { }
                gatt = null;
            }
        }
        public void onMtuChanged(BluetoothGatt g, int mtu, int status) { g.discoverServices(); }
        public void onServicesDiscovered(BluetoothGatt g, int status) {
            BluetoothGattService s = g.getService(NUS);
            if (s == null) { g.disconnect(); return; }
            BluetoothGattCharacteristic tx = s.getCharacteristic(TX);
            g.setCharacteristicNotification(tx, true);
            BluetoothGattDescriptor dsc = tx.getDescriptor(CCC);
            if (dsc != null) { dsc.setValue(BluetoothGattDescriptor.ENABLE_NOTIFICATION_VALUE); g.writeDescriptor(dsc); }
            state = "connected";
            lastData = System.currentTimeMillis();
        }
        public void onCharacteristicChanged(BluetoothGatt g, BluetoothGattCharacteristic c) {
            byte[] v = c.getValue();
            if (v != null) feed(v);
        }
    };

    // ---------- CRSF ----------
    final byte[] buf = new byte[4096]; int blen = 0;

    static int crc8(byte[] d, int off, int n) {
        int c = 0;
        for (int i = 0; i < n; i++) {
            c ^= d[off + i] & 0xFF;
            for (int k = 0; k < 8; k++) c = (c & 0x80) != 0 ? ((c << 1) ^ 0xD5) & 0xFF : (c << 1) & 0xFF;
        }
        return c;
    }

    synchronized void feed(byte[] d) {
        lastData = System.currentTimeMillis();
        if (blen + d.length > buf.length) blen = 0;
        System.arraycopy(d, 0, buf, blen, d.length); blen += d.length;
        int i = 0;
        while (blen - i >= 2) {
            int s = buf[i] & 0xFF;
            if (s != 0xC8 && s != 0xEA && s != 0xEE && s != 0xEC) { i++; continue; }
            int n = buf[i + 1] & 0xFF;
            if (n < 2 || n > 62) { i++; continue; }
            if (blen - i < n + 2) break;
            if (crc8(buf, i + 2, n - 1) != (buf[i + 1 + n] & 0xFF)) { i++; continue; }
            try { frame(buf[i + 2] & 0xFF, buf, i + 3, n - 2); } catch (Throwable t) { }
            frames++;
            i += n + 2;
        }
        System.arraycopy(buf, i, buf, 0, blen - i); blen -= i;
    }

    static int u8(byte[] b, int o) { return b[o] & 0xFF; }
    static int u16(byte[] b, int o) { return ((b[o] & 0xFF) << 8) | (b[o + 1] & 0xFF); }
    static int s32(byte[] b, int o) { return ((b[o] & 0xFF) << 24) | ((b[o + 1] & 0xFF) << 16) | ((b[o + 2] & 0xFF) << 8) | (b[o + 3] & 0xFF); }
    static int le32(byte[] b, int o) { return (b[o] & 0xFF) | ((b[o + 1] & 0xFF) << 8) | ((b[o + 2] & 0xFF) << 16) | ((b[o + 3] & 0xFF) << 24); }
    static int le16(byte[] b, int o) { return (b[o] & 0xFF) | ((b[o + 1] & 0xFF) << 8); }

    void frame(int t, byte[] p, int o, int n) {
        if (t == 0x7D && n >= 7) {                       // Absender-MAC + dBm vor jedem Telemetrie-Rahmen
            StringBuilder m = new StringBuilder();
            for (int i = 0; i < 6; i++) { if (i > 0) m.append(':'); m.append(String.format("%02X", p[o + i] & 0xFF)); }
            mac = m.toString();
            return;
        }
        if (t == 0x7A && n >= 3) { espRssi = (byte) p[o]; espPps = u8(p, o + 1); return; }
        if (t == 0x7C && n >= 17) {                      // eigenes GPS des ESP: lat, lon int32 1e7, alt, km/h*10, Kurs*10, sats, fix, hdop*10 (little endian)
            meLat = le32(p, o) / 1e7; meLon = le32(p, o + 4) / 1e7; meKmh = le16(p, o + 10) / 10.0; meCrs = le16(p, o + 12) / 10.0;
            meSats = u8(p, o + 14); meFix = u8(p, o + 15); tMe = System.currentTimeMillis();
            if (meFix > 0 && a.gps != null) a.gps.ext(meLat, meLon, meKmh, meCrs, meSats);
            return;
        }
        if (mac.length() > 0 && !mac.equals(carMac) && carMac.length() > 0) return;   // nur der Mojave (andere Sender ignorieren)
        if (t == 0x02 && n >= 15) {
            lat = s32(p, o) / 1e7; lon = s32(p, o + 4) / 1e7; kmh = u16(p, o + 8) / 10.0; hdg = u16(p, o + 10) / 100.0;
            alt = u16(p, o + 12) - 1000; sats = u8(p, o + 14); tGps = System.currentTimeMillis();
            push();
        } else if (t == 0x08 && n >= 8) {
            volt = u16(p, o) / 10.0; amp = u16(p, o + 2) / 10.0;
            mah = (u8(p, o + 4) << 16) | (u8(p, o + 5) << 8) | u8(p, o + 6); pct = u8(p, o + 7); tBat = System.currentTimeMillis();
            push();
        } else if (t == 0x14 && n >= 10) {
            int r1 = u8(p, o), r2 = u8(p, o + 1), ant = u8(p, o + 4);
            int r = (ant == 0 || r2 == 0) ? r1 : r2;
            rssi = r > 127 ? r - 256 : -r; lq = u8(p, o + 2); tLink = System.currentTimeMillis();
            push();
        } else if (t == 0x21) {
            int e = o; while (e < o + n && p[e] != 0) e++;
            mode = new String(p, o, Math.min(16, e - o));
        }
    }

    long tPush = 0;
    void push() {
        long now = System.currentTimeMillis();
        if (now - tPush < 250) return;
        tPush = now;
        a.js("window.ctCar&&ctCar(" + (tGps > 0 ? lat + "," + lon : "null,null") + "," + kmh + "," + hdg + "," + sats + ","
                + (tBat > 0 ? volt : -1) + "," + pct + "," + mah + "," + lq + "," + rssi + "," + Client.q(mode) + ","
                + (tGps > 0 ? (now - tGps) / 1000 : -1) + ")");
    }
}
