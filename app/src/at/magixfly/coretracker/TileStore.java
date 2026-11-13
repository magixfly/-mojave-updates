package at.magixfly.coretracker;

import android.net.ConnectivityManager;
import android.net.NetworkInfo;

import java.io.ByteArrayOutputStream;
import java.io.File;
import java.io.FileOutputStream;
import java.io.InputStream;
import java.net.HttpURLConnection;
import java.net.URL;
import java.util.concurrent.ArrayBlockingQueue;
import java.util.concurrent.BlockingQueue;
import java.util.concurrent.atomic.AtomicLong;

/**
 * Kartenkacheln auf der Box: liefert Kacheln an den Tracker (aus dem Speicher der Box)
 * und lädt im Hintergrund Wien + Niederösterreich vor (nur über WLAN, z. B. Hotspot XVII).
 * Reihenfolge: Zoom 8–16 komplett, dann Zoom 17/18 ringförmig von St. Pölten nach außen.
 */
class TileStore {
    // Wien + Niederösterreich (Rechteck)
    static final double LAT_S = 47.42, LAT_N = 49.02, LON_W = 14.45, LON_E = 17.07;
    static final double C_LAT = 48.1874, C_LON = 15.6139;       // Start: St. Pölten
    static final int ZMIN = 8, ZFULL = 16, ZMAX = 18;
    static final long KEEP_FREE = 8L * 1024 * 1024 * 1024;     // mindestens 8 GB frei lassen
    static final String SRC = "https://maps.wien.gv.at/basemap/bmaporthofoto30cm/normal/google3857/%d/%d/%d.jpeg";
    static final int WORKERS = 8;

    final MainActivity a;
    final File dir;
    final BlockingQueue<long[]> q = new ArrayBlockingQueue<long[]>(400);
    final AtomicLong done = new AtomicLong(), loaded = new AtomicLong(), bytes = new AtomicLong();
    volatile long total = 1;
    volatile String phase = "";
    volatile boolean finished = false, paused = false, full = false;

    TileStore(MainActivity a) {
        this.a = a;
        dir = new File(a.getFilesDir(), "tiles");
        dir.mkdirs();
    }

    File file(int z, int x, int y) { return new File(dir, z + "/" + x + "/" + y + ".jpg"); }

    /** Kachel aus dem Box-Speicher, sonst vom Pi holen und speichern. null = nicht verfügbar. */
    byte[] get(int z, int x, int y, String piBase) {
        File f = file(z, x, y);
        if (f.length() > 0) return read(f);
        if (piBase != null) {
            byte[] d = http(piBase + "/tile/" + z + "/" + x + "/" + y, 3000);
            if (d != null && d.length > 0) { save(f, d); return d; }
        }
        return null;
    }

    // ---------- Hintergrund-Download ----------
    void start() {
        long t = 0;
        for (int z = ZMIN; z <= ZMAX; z++) t += count(z);
        total = t;
        for (int i = 0; i < WORKERS; i++) new Thread(new TileWorker(this)).start();
        new Thread(new TileProducer(this)).start();
    }

    long count(int z) {
        long w = lonX(LON_E, z) - lonX(LON_W, z) + 1, h = latY(LAT_S, z) - latY(LAT_N, z) + 1;
        return w * h;
    }

    String status() {
        long d = done.get();
        int pct = (int) Math.min(100, d * 100 / Math.max(1, total));
        String s = "Karten " + pct + " % · " + phase + " · " + (bytes.get() / (1024 * 1024)) + " MB geladen";
        if (finished) s = "Karten Wien + NÖ komplett";
        else if (full) s = "Karten: Speicher fast voll – Download pausiert";
        else if (paused) s = "Karten " + pct + " % · wartet auf WLAN (Hotspot)";
        return s;
    }

    int percent() { return (int) Math.min(100, done.get() * 100 / Math.max(1, total)); }

    boolean onWifi() {
        try {
            ConnectivityManager cm = (ConnectivityManager) a.getSystemService("connectivity");
            NetworkInfo ni = cm.getActiveNetworkInfo();
            return ni != null && ni.isConnected() && ni.getType() == 1;
        } catch (Throwable t) { return false; }
    }

    // ---------- Hilfen ----------
    static long lonX(double lon, int z) { return (long) Math.floor((lon + 180) / 360 * (1L << z)); }
    static long latY(double lat, int z) {
        double r = Math.toRadians(lat);
        return (long) Math.floor((1 - Math.log(Math.tan(r) + 1 / Math.cos(r)) / Math.PI) / 2 * (1L << z));
    }

    /** Daten, leeres Array bei 404 (keine Kachel an dieser Stelle), null bei Netzfehler. */
    static byte[] http(String url, int timeout) {
        try {
            HttpURLConnection c = (HttpURLConnection) new URL(url).openConnection();
            c.setConnectTimeout(timeout);
            c.setReadTimeout(timeout);
            c.setRequestProperty("User-Agent", "CoreTracker-Box/1.3");
            int code = c.getResponseCode();
            if (code == 404 || code == 400) { c.disconnect(); return new byte[0]; }
            if (code != 200) { c.disconnect(); return null; }
            InputStream in = c.getInputStream();
            ByteArrayOutputStream o = new ByteArrayOutputStream();
            byte[] b = new byte[16384];
            int n;
            while ((n = in.read(b)) > 0) o.write(b, 0, n);
            in.close();
            c.disconnect();
            return o.toByteArray();
        } catch (Throwable t) { return null; }
    }

    static void save(File f, byte[] d) {
        try {
            f.getParentFile().mkdirs();
            File tmp = new File(f.getPath() + ".tmp");
            FileOutputStream o = new FileOutputStream(tmp);
            o.write(d);
            o.close();
            tmp.renameTo(f);
        } catch (Throwable t) { }
    }

    static byte[] read(File f) {
        try {
            java.io.FileInputStream in = new java.io.FileInputStream(f);
            byte[] d = new byte[(int) f.length()];
            int off = 0, n;
            while (off < d.length && (n = in.read(d, off, d.length - off)) > 0) off += n;
            in.close();
            return d;
        } catch (Throwable t) { return null; }
    }
}
