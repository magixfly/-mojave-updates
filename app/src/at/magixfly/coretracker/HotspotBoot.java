package at.magixfly.coretracker;

import android.content.Context;
import android.os.SystemClock;
import android.util.Log;

import java.io.DataInputStream;
import java.io.OutputStream;
import java.net.Socket;
import java.nio.ByteBuffer;
import java.nio.ByteOrder;

/**
 * V1.39: Nach dem Start der Box den WLAN-Hotspot (Internet über SIM) automatisch einschalten.
 * Android hat dafür keinen Shell-Befehl → die App verbindet sich mit dem eigenen ADB der Box
 * (127.0.0.1:5555, persist.adb.tcp.port, ohne Bestätigung) und tippt in den Hotspot-Einstellungen
 * auf den Schalter. Name, Passwort und Band bleiben wie vom User eingestellt.
 */
class HotspotBoot {
    static volatile boolean started = false;

    /** Nur in den ersten 10 min nach dem Einschalten und nur einmal pro Start. */
    static void maybe(final Context c) {
        if (started || SystemClock.elapsedRealtime() > 10 * 60 * 1000L) return;
        if (!c.getSharedPreferences("ct", 0).getBoolean("apAuto", true)) return;
        started = true;
        new Thread(new Runnable() { public void run() {
            try {
                Thread.sleep(20000);                           // System fertig starten lassen
                String r = shell("if dumpsys tethering | grep -q TetheredState; then echo schon_an; else "
                    + "am start -a android.settings.TETHER_SETTINGS >/dev/null; sleep 4; input tap 1866 304; sleep 4; "
                    + "am start -n at.magixfly.coretracker/.MainActivity >/dev/null; sleep 2; "
                    + "dumpsys tethering | grep -c TetheredState; fi");
                Log.d("CTAP", "Hotspot: " + r.trim());
            } catch (Throwable t) { Log.d("CTAP", "Hotspot-Fehler: " + t); }
        } }).start();
    }

    // ---- minimaler ADB-Client (ohne RSA, da ro.adb.secure=0) ----
    static final int CNXN = 0x4e584e43, OPEN = 0x4e45504f, OKAY = 0x59414b4f, WRTE = 0x45545257, CLSE = 0x45534c43;

    static String shell(String cmd) throws Exception {
        Socket s = new Socket("127.0.0.1", 5555);
        s.setSoTimeout(30000);
        OutputStream o = s.getOutputStream();
        DataInputStream in = new DataInputStream(s.getInputStream());
        send(o, CNXN, 0x01000001, 256 * 1024, "host::\0".getBytes("UTF-8"));
        int[] h = read(in);
        if (h[0] != CNXN) { s.close(); throw new Exception("kein CNXN (" + Integer.toHexString(h[0]) + ")"); }
        send(o, OPEN, 1, 0, ("shell:" + cmd + "\0").getBytes("UTF-8"));
        StringBuilder out = new StringBuilder();
        int remote = 0;
        while (true) {
            h = read(in);
            if (h[0] == OKAY) remote = h[1];
            else if (h[0] == WRTE) { out.append(new String(last, "UTF-8")); send(o, OKAY, 1, h[1], new byte[0]); }
            else if (h[0] == CLSE) { send(o, CLSE, 1, remote, new byte[0]); break; }
        }
        s.close();
        return out.toString();
    }

    static byte[] last = new byte[0];

    static void send(OutputStream o, int cmd, int a0, int a1, byte[] data) throws Exception {
        ByteBuffer b = ByteBuffer.allocate(24 + data.length).order(ByteOrder.LITTLE_ENDIAN);
        int sum = 0; for (byte x : data) sum += (x & 0xff);
        b.putInt(cmd).putInt(a0).putInt(a1).putInt(data.length).putInt(sum).putInt(~cmd).put(data);
        o.write(b.array()); o.flush();
    }

    static int[] read(DataInputStream in) throws Exception {
        byte[] hb = new byte[24]; in.readFully(hb);
        ByteBuffer b = ByteBuffer.wrap(hb).order(ByteOrder.LITTLE_ENDIAN);
        int cmd = b.getInt(), a0 = b.getInt(), a1 = b.getInt(), len = b.getInt();
        last = new byte[len]; if (len > 0) in.readFully(last);
        return new int[]{cmd, a0, a1};
    }
}
