package at.magixfly.coretracker;

import android.bluetooth.*;
import android.bluetooth.le.*;
import android.content.Context;
import java.io.*;
import java.net.Socket;
import java.util.UUID;

/** V1.97: own ESP (ESP-NOW receiver, firmware V1.5) via Bluetooth LE (Nordic UART service).
 *  Bytes from the ESP go to the tracker program on the box (127.0.0.1:8099), text from there goes to the ESP. */
class BleEsp {
    static final UUID NUS = UUID.fromString("6e400001-b5a3-f393-e0a9-e50e24dcca9e");
    static final UUID RX = UUID.fromString("6e400002-b5a3-f393-e0a9-e50e24dcca9e");   // to the ESP
    static final UUID TX = UUID.fromString("6e400003-b5a3-f393-e0a9-e50e24dcca9e");   // from the ESP
    static final UUID CCC = UUID.fromString("00002902-0000-1000-8000-00805f9b34fb");
    static final String NAME = "CoreTracker-ESP";
    static volatile String state = "off";
    static BleEsp me;

    final Context ctx;
    BluetoothAdapter ad;
    BluetoothGatt gatt;
    BluetoothGattCharacteristic rx;
    volatile Socket sock;
    volatile OutputStream out;
    volatile boolean scanning = false;
    String devName = NAME;

    static synchronized void start(Context c) {
        if (me != null) return;
        me = new BleEsp(c.getApplicationContext());
        new Thread(new Runnable() { public void run() { me.loop(); } }).start();
    }

    BleEsp(Context c) { ctx = c; }

    void loop() {
        try {   // runtime permissions: the app grants them itself through the root shell
            HotspotBoot.shell("pm grant at.magixfly.coretracker android.permission.BLUETOOTH_SCAN; pm grant at.magixfly.coretracker android.permission.BLUETOOTH_CONNECT; pm grant at.magixfly.coretracker android.permission.ACCESS_FINE_LOCATION; svc bluetooth enable");
        } catch (Throwable t) { }
        BluetoothManager bm = (BluetoothManager) ctx.getSystemService(Context.BLUETOOTH_SERVICE);
        ad = bm == null ? null : bm.getAdapter();
        while (true) {
            try {
                if (ad == null || !ad.isEnabled()) { state = "Bluetooth off"; sleep(5000); continue; }
                if (gatt == null && !scanning) scan();
                if (gatt != null && sock == null) connectSock();
            } catch (Throwable t) { state = "error " + t.getMessage(); }
            sleep(3000);
        }
    }

    static void sleep(long ms) { try { Thread.sleep(ms); } catch (Throwable t) { } }

    ScanCallback cb = new ScanCallback() {
        public void onScanResult(int type, ScanResult r) {
            BluetoothDevice d = r.getDevice();
            String n = r.getScanRecord() != null ? r.getScanRecord().getDeviceName() : null;
            if (n == null || !n.startsWith(NAME) || gatt != null) return;
            devName = n;
            stopScan();
            state = "connecting";
            gatt = d.connectGatt(ctx, false, gcb, BluetoothDevice.TRANSPORT_LE);
        }
    };

    void scan() {
        BluetoothLeScanner sc = ad.getBluetoothLeScanner();
        if (sc == null) return;
        scanning = true;
        state = "searching";
        sc.startScan(null, new ScanSettings.Builder().setScanMode(ScanSettings.SCAN_MODE_LOW_LATENCY).build(), cb);
        new Thread(new Runnable() { public void run() { sleep(15000); if (scanning) stopScan(); } }).start();
    }

    void stopScan() {
        scanning = false;
        try { ad.getBluetoothLeScanner().stopScan(cb); } catch (Throwable t) { }
    }

    BluetoothGattCallback gcb = new BluetoothGattCallback() {
        public void onConnectionStateChange(BluetoothGatt g, int status, int st) {
            if (st == BluetoothProfile.STATE_CONNECTED) {
                g.requestConnectionPriority(BluetoothGatt.CONNECTION_PRIORITY_HIGH);
                g.requestMtu(247);   // ESP sends 180-byte notifications
            } else {
                state = "lost";
                try { g.close(); } catch (Throwable t) { }
                gatt = null; rx = null;
                closeSock();
            }
        }
        public void onMtuChanged(BluetoothGatt g, int mtu, int status) { g.discoverServices(); }
        public void onServicesDiscovered(BluetoothGatt g, int status) {
            BluetoothGattService s = g.getService(NUS);
            if (s == null) { g.disconnect(); return; }
            rx = s.getCharacteristic(RX);
            BluetoothGattCharacteristic tx = s.getCharacteristic(TX);
            g.setCharacteristicNotification(tx, true);
            BluetoothGattDescriptor dsc = tx.getDescriptor(CCC);
            if (dsc != null) { dsc.setValue(BluetoothGattDescriptor.ENABLE_NOTIFICATION_VALUE); g.writeDescriptor(dsc); }
            state = "connected";
        }
        public void onCharacteristicChanged(BluetoothGatt g, BluetoothGattCharacteristic c) {
            byte[] v = c.getValue();
            OutputStream o = out;
            if (v == null || o == null) return;
            try { o.write(v); o.flush(); } catch (Throwable t) { closeSock(); }
        }
    };

    void connectSock() {
        try {
            Socket s = new Socket("127.0.0.1", 8099);
            s.setTcpNoDelay(true);
            out = s.getOutputStream();
            out.write(("@dev " + devName + "\n").getBytes());
            sock = s;
            final InputStream in = s.getInputStream();
            new Thread(new Runnable() { public void run() {   // text from the tracker program -> ESP
                byte[] b = new byte[180];
                try {
                    int n;
                    while ((n = in.read(b)) > 0) {
                        BluetoothGattCharacteristic r = rx;
                        if (r != null && gatt != null) {
                            byte[] v = new byte[n];
                            System.arraycopy(b, 0, v, 0, n);
                            r.setValue(v);
                            gatt.writeCharacteristic(r);
                        }
                    }
                } catch (Throwable t) { }
                closeSock();
            } }).start();
        } catch (Throwable t) { sock = null; out = null; }   // tracker program not running yet
    }

    synchronized void closeSock() {
        try { if (sock != null) sock.close(); } catch (Throwable t) { }
        sock = null; out = null;
    }
}
