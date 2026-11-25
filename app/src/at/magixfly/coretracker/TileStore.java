package at.magixfly.coretracker;

import android.net.ConnectivityManager;
import android.net.NetworkInfo;

import java.io.ByteArrayOutputStream;
import java.io.File;
import java.io.FileOutputStream;
import java.io.InputStream;
import java.io.OutputStream;
import java.net.HttpURLConnection;
import java.net.URL;
import java.util.ArrayList;
import java.util.concurrent.ArrayBlockingQueue;
import java.util.concurrent.BlockingQueue;
import java.util.concurrent.atomic.AtomicLong;
import org.json.JSONArray;
import org.json.JSONObject;

/**
 * Kartenkacheln auf der Box.
 * V2.06 (Plan Kartenabgleich 24.11.): statt Rechteck Wien + NÖ gilt die gemeinsame Gebietsliste gebiete.json
 * (Zentrale am PC → Tracker-Pi → GitHub). Kacheln kommen aus: Box-Speicher → Zentrale → Pi → basemap.at.
 * Kacheln außerhalb der Liste werden einmal je Listenversion gelöscht. Neue Orte der Box gehen an Zentrale/Pi (/api/orte).
 */
class TileStore {
    static final double C_LAT = 48.1874, C_LON = 15.6139;       // Zuhause St. Pölten
    static final long KEEP_FREE = 8L * 1024 * 1024 * 1024;     // mindestens 8 GB frei lassen
    static final String SRC = "https://maps.wien.gv.at/basemap/bmaporthofoto30cm/normal/google3857/%d/%d/%d.jpeg";
    static final String OVL = "https://maps.wien.gv.at/basemap/bmapoverlay/normal/google3857/%d/%d/%d.png";   // V2.01: Ortsnamen/Straßen
    static volatile String PI = "http://192.168.178.111:8080";   // V2.17: tracker on the network cable now (.111), Wi-Fi .214 as second try
    static final String GH = "https://raw.githubusercontent.com/magixfly/-mojave-updates/main/bodenstation/";
    static final int WORKERS = 6;

    final MainActivity a;
    final File dir, ovlDir, listFile;
    final BlockingQueue<long[]> q = new ArrayBlockingQueue<long[]>(400);
    final AtomicLong done = new AtomicLong(), loaded = new AtomicLong(), bytes = new AtomicLong();
    volatile long total = 1;
    volatile String phase = "starting";
    volatile int cleanPct = -1;
    volatile long deleted = 0;
    volatile boolean finished = false, paused = false, full = false, stopped = false;
    volatile long lastOk = 0;
    volatile Areas areas;
    volatile String listSrc = "";
    volatile boolean zOk = false, piOk = false;   // Zentrale / Tracker-Pi erreichbar

    TileStore(MainActivity a) {
        this.a = a;
        dir = new File(a.getFilesDir(), "tiles");
        dir.mkdirs();
        ovlDir = new File(a.getFilesDir(), "ovl");
        listFile = new File(a.getFilesDir(), "gebiete.json");
        stopped = a.prefs.getBoolean("dlStop", false);
    }

    File file(int z, int x, int y) { return new File(dir, z + "/" + x + "/" + y + ".jpg"); }
    File ovlFile(int z, int x, int y) { return new File(ovlDir, z + "/" + x + "/" + y + ".png"); }

    String zentrale() { String z = a.prefs.getString("zentrale", "http://192.168.178.243:8091").trim(); while (z.endsWith("/")) z = z.substring(0, z.length() - 1); return z; }
    int zcap() { return Math.max(8, Math.min(19, a.prefs.getInt("map_zmax", 19))); }

    /** Kachel für die Karte: Box-Speicher → Zentrale → Pi → basemap.at. Gespeichert wird nur, was in der Liste liegt. null/leer = nicht verfügbar. */
    byte[] get(int z, int x, int y, boolean ovl) {
        File f = ovl ? ovlFile(z, x, y) : file(z, x, y);
        if (f.exists()) { if (f.length() == 0) return null; byte[] d0 = read(f); return !ovl && weiss(d0) ? new byte[0] : d0; }
        if (!online()) return null;
        byte[] d = fetch(z, x, y, ovl, 4000);
        if (d == null) return null;
        if (!ovl && weiss(d)) d = new byte[0];   // V2.25: basemap.at is white outside Austria -> empty = dark background
        Areas ar = areas;
        if (ar == null || ar.has(z, x, y)) save(f, d);
        if (!ovl && d.length > 0) { loaded.incrementAndGet(); bytes.addAndGet(d.length); }
        return d;
    }

    /** V2.25: tile is (almost) completely white = outside Austria at basemap.at */
    static boolean weiss(byte[] d) {
        try {
            if (d == null || d.length == 0 || d.length > 20000) return false;   // white tiles are small JPEGs
            android.graphics.BitmapFactory.Options o = new android.graphics.BitmapFactory.Options(); o.inSampleSize = 16;
            android.graphics.Bitmap b = android.graphics.BitmapFactory.decodeByteArray(d, 0, d.length, o);
            if (b == null) return false;
            for (int y = 0; y < b.getHeight(); y++) for (int x = 0; x < b.getWidth(); x++) { int c = b.getPixel(x, y); if (((c >> 16) & 255) < 240 || ((c >> 8) & 255) < 240 || (c & 255) < 240) { b.recycle(); return false; } }
            b.recycle(); return true;
        } catch (Throwable t) { return false; }
    }

    /** Daten (leer = gibt es nicht) oder null (Netzfehler). Reihenfolge Zentrale → Pi → basemap.at. */
    byte[] fetch(int z, int x, int y, boolean ovl, int timeout) {
        String path = (ovl ? "/tileo/" : "/tile/") + z + "/" + x + "/" + y + (ovl ? ".png" : ".jpg");
        String zz = zentrale();
        if (zOk && zz.length() > 0) { byte[] d = http(zz + path, 2500); if (d != null && d.length > 0) return d; }
        if (piOk) { byte[] d = http(PI + path, 2500); if (d != null && d.length > 0) return d; }
        return http(String.format(ovl ? OVL : SRC, z, y, x), timeout);
    }

    // ---------- Fortschritt ----------
    void loadTotal() {
        long b = a.prefs.getLong("tileBytes", -1);
        if (b >= 0) { bytes.set(b); loaded.set(a.prefs.getLong("tileCount", 0)); return; }
        long[] r = new long[2]; dirSize(dir, r);
        bytes.set(r[0]); loaded.set(r[1]);
        saveTotal();
    }
    void saveTotal() { a.prefs.edit().putLong("tileBytes", bytes.get()).putLong("tileCount", loaded.get()).apply(); }
    static void dirSize(File f, long[] r) {
        if (f.isFile()) { if (f.length() > 0) { r[0] += f.length(); r[1]++; } return; }
        File[] l = f.listFiles();
        if (l != null) for (File x : l) dirSize(x, r);
    }
    long estimate() { long n = loaded.get(); double avg = n > 200 ? (double) bytes.get() / n : 22000; return (long) (total * avg); }

    int percent() {
        if (cleanPct >= 0 && "cleaning".equals(phase)) return cleanPct;
        return (int) Math.min(100, done.get() * 100 / Math.max(1, total));
    }

    /** kurzer Text für die Kopfzeile */
    String stateText() {
        if ("list".equals(phase)) return "reading area list";
        if ("cleaning".equals(phase)) return "deleting outside areas · " + deleted;
        if (finished) return "complete";
        if (full) return "storage full";
        if (stopped) return "stopped";
        if (netType() == null) return "offline";
        if (paused) return "waiting";
        return (loadingNow() ? "loading" : "checking") + (zOk ? " from PC" : piOk ? " from tracker" : "");
    }

    void start() {
        loadTotal();
        new Thread(new Runnable() { public void run() { syncLoop(); } }).start();
        for (int i = 0; i < WORKERS; i++) new Thread(new TileWorker(this)).start();
        new Thread(new Runnable() { public void run() { placesLoop(); } }).start();
    }

    // ---------- Gebietsliste ----------
    void probe() {
        String zz = zentrale();
        zOk = zz.length() > 0 && http(zz + "/api/ping", 1500) != null;
        piOk = false;   // V2.18: the box no longer uses the tracker - maps only from the PC centre, else basemap.at
    }

    /** V2.07: Zentrale (/api/ping listver) bzw. Pi (/gebiete.json ver) hat eine andere Listenversion als die geladene */
    boolean listVerChanged() {
        Areas ar = areas;
        if (ar == null) return true;
        try {
            String zz = zentrale();
            if (zOk) { byte[] d = http(zz + "/api/ping", 2000); if (d != null && d.length > 0) { int v = new JSONObject(new String(d, "UTF-8")).optInt("listver", ar.ver); return v != ar.ver; } }
            if (piOk) { byte[] d = http(PI + "/gebiete.json", 3000); if (d != null && d.length > 10) return new JSONObject(new String(d, "UTF-8")).optInt("ver", ar.ver) != ar.ver; }
        } catch (Throwable t) { }
        return false;
    }

    JSONObject loadList() {
        String zz = zentrale();
        String[] src = {zz.length() > 0 ? zz + "/gebiete.json" : null, null, GH + "gebiete.json", GH + "gebiete_default.json"};
        for (String u : src) {
            if (u == null) continue;
            byte[] d = http(u + "?t=" + System.currentTimeMillis(), 6000);
            if (d == null || d.length < 10) continue;
            try {
                JSONObject j = new JSONObject(new String(d, "UTF-8"));
                if (j.has("areas")) { save(listFile, d); listSrc = u.startsWith(PI) ? "tracker" : u.startsWith("https") ? "GitHub" : "PC"; return j; }
            } catch (Throwable t) { }
        }
        try { if (listFile.exists()) { listSrc = "saved copy"; return new JSONObject(new String(read(listFile), "UTF-8")); } } catch (Throwable t) { }
        return null;
    }

    void syncLoop() {
        int lastVer = -1;
        while (true) {
            try {
                phase = "list";
                probe();
                JSONObject j = loadList();
                if (j != null) {
                    Areas ar = new Areas(j, zcap());
                    areas = ar;
                    String tag = ar.ver + "/" + ar.zcap;
                    if (!tag.equals(a.prefs.getString("areasCleaned", ""))) {
                        clean(ar);
                        a.prefs.edit().putString("areasCleaned", tag).apply();
                    }
                    if (ar.ver != lastVer || !finished) {
                        lastVer = ar.ver;
                        produce(ar);
                    }
                }
            } catch (Throwable t) { android.util.Log.d("CTAP", "sync: " + t); }
            phase = finished ? "done" : phase;
            if (!listVerChanged()) for (int i = 0; i < 30; i++) {   // V2.14: list already changed -> at once; sonst alle 30 min neu laden, früher wenn die Zentrale eine neue Listenversion meldet
                try { Thread.sleep(60000); } catch (Throwable t) { }
                probe();
                if (listVerChanged()) break;
            }
        }
    }

    /** alle Kacheln der Liste in die Warteschlange, kleinste Zoomstufe zuerst, je Stufe von zuhause nach außen */
    void produce(Areas ar) throws InterruptedException {
        finished = false;
        ArrayList<long[]> jobs = new ArrayList<long[]>(ar.want.size());
        for (Long k : ar.want) jobs.add(new long[]{k >>> 56, (k >>> 28) & 0xFFFFFFFL, k & 0xFFFFFFFL});
        final long[][] c = new long[20][];
        for (int z = 0; z < 20; z++) c[z] = new long[]{lonX(C_LON, z), latY(C_LAT, z)};
        final java.util.HashMap<Long, Long> pr = ar.prio;
        java.util.Collections.sort(jobs, new java.util.Comparator<long[]>() { public int compare(long[] p, long[] q) {
            Long a1 = pr.get(Areas.key((int) p[0], p[1], p[2])), a2 = pr.get(Areas.key((int) q[0], q[1], q[2]));   // V2.14: "load first" areas before everything
            long v1 = a1 == null ? 0 : a1, v2 = a2 == null ? 0 : a2;
            if (v1 != v2) return v1 > v2 ? -1 : 1;
            if (p[0] != q[0]) return p[0] < q[0] ? -1 : 1;
            long[] h = c[(int) p[0]];
            long dp = Math.max(Math.abs(p[1] - h[0]), Math.abs(p[2] - h[1])), dq = Math.max(Math.abs(q[1] - h[0]), Math.abs(q[2] - h[1]));
            return dp < dq ? -1 : dp > dq ? 1 : 0;
        } });
        total = jobs.size(); done.set(0);
        phase = "loading";
        long chk = System.currentTimeMillis();
        for (long[] t : jobs) {
            if (areas != ar) return;                              // neue Liste -> neu anfangen
            if (System.currentTimeMillis() - chk > 60000) { chk = System.currentTimeMillis(); probe(); if (listVerChanged()) { q.clear(); return; } }   // V2.14: list changed on the PC (e.g. "load first") -> start again at once
            File f = file((int) t[0], (int) t[1], (int) t[2]);
            if (f.exists()) { done.incrementAndGet(); continue; }
            while (full) Thread.sleep(60000);
            q.put(t);
        }
        for (int i = 0; i < WORKERS; i++) q.put(new long[]{-1, 0, 0});
    }

    /** Kacheln (Luftbild + Ortsnamen) außerhalb der Liste löschen – ganze Spalten-Ordner auf einmal, wenn darin nichts gebraucht wird */
    void clean(Areas ar) {
        phase = "cleaning"; cleanPct = 0; deleted = 0;
        ArrayList<File> cols = new ArrayList<File>();
        for (File base : new File[]{dir, ovlDir}) {
            File[] zs = base.listFiles();
            if (zs == null) continue;
            for (File zd : zs) { File[] xs = zd.listFiles(); if (xs != null) for (File xd : xs) cols.add(xd); }
        }
        int n = 0;
        for (File xd : cols) {
            n++; cleanPct = (int) (n * 100L / Math.max(1, cols.size()));
            try {
                int z = Integer.parseInt(xd.getParentFile().getName()); long x = Long.parseLong(xd.getName());
                File[] ys = xd.listFiles();
                if (ys == null) continue;
                for (File yf : ys) {
                    String nm = yf.getName(); int dot = nm.indexOf('.');
                    long y; try { y = Long.parseLong(dot > 0 ? nm.substring(0, dot) : nm); } catch (Throwable t) { continue; }
                    if (!ar.has(z, x, y)) { long l = yf.length(); if (yf.delete()) { deleted++; if (xd.getPath().startsWith(dir.getPath()) && l > 0) { bytes.addAndGet(-l); loaded.decrementAndGet(); } } }
                }
                String[] left = xd.list();
                if (left != null && left.length == 0) xd.delete();
            } catch (Throwable t) { }
        }
        for (File base : new File[]{dir, ovlDir}) { File[] zs = base.listFiles(); if (zs != null) for (File zd : zs) { String[] l = zd.list(); if (l != null && l.length == 0) zd.delete(); } }
        if (bytes.get() < 0) { long[] r = new long[2]; dirSize(dir, r); bytes.set(r[0]); loaded.set(r[1]); }
        saveTotal();
        cleanPct = -1;
        android.util.Log.d("CTAP", "areas clean: " + deleted + " deleted");
    }

    // ---------- neue Orte melden ----------
    /** von Gps bzw. BleEsp: aktuelle Position der Box (nur genaue Werte) */
    volatile long hereT = 0;
    void here(double lat, double lon, float acc) {
        long now = System.currentTimeMillis();
        if (now - hereT < 20000) return;                  // höchstens alle 20 s prüfen
        hereT = now;
        Areas ar = areas;
        if (ar == null || acc > 300 || ar.covers(lat, lon)) return;
        try {
            JSONArray p = new JSONArray(a.prefs.getString("newPlaces", "[]"));
            for (int i = 0; i < p.length(); i++) { JSONObject o = p.getJSONObject(i); if (Areas.dist(lat, lon, o.getDouble("lat"), o.getDouble("lon")) < 500) return; }
            p.put(new JSONObject().put("lat", Math.round(lat * 1e5) / 1e5).put("lon", Math.round(lon * 1e5) / 1e5).put("t", System.currentTimeMillis() / 1000));
            a.prefs.edit().putString("newPlaces", p.toString()).apply();
            android.util.Log.d("CTAP", "new place " + lat + "," + lon);
        } catch (Throwable t) { }
    }

    void placesLoop() {
        while (true) {
            try { Thread.sleep(60000); } catch (Throwable t) { }
            try {
                String s = a.prefs.getString("newPlaces", "[]");
                if (s.equals("[]")) continue;
                String body = new JSONObject().put("dev", "box").put("pts", new JSONArray(s)).toString();
                String zz = zentrale();
                boolean ok = (zOk && zz.length() > 0 && post(zz + "/api/orte", body)) || (piOk && post(PI + "/api/orte", body));
                if (ok) a.prefs.edit().putString("newPlaces", "[]").apply();
            } catch (Throwable t) { }
        }
    }

    static boolean post(String url, String body) {
        try {
            HttpURLConnection c = (HttpURLConnection) new URL(url).openConnection();
            c.setConnectTimeout(3000); c.setReadTimeout(5000);
            c.setRequestMethod("POST"); c.setDoOutput(true);
            c.setRequestProperty("Content-Type", "application/json");
            OutputStream o = c.getOutputStream(); o.write(body.getBytes("UTF-8")); o.close();
            int code = c.getResponseCode(); c.disconnect();
            return code == 200;
        } catch (Throwable t) { return false; }
    }

    // ---------- Netz ----------
    boolean online() { return netType() != null; }
    String netType() {
        try {
            ConnectivityManager cm = (ConnectivityManager) a.getSystemService("connectivity");
            NetworkInfo ni = cm.getActiveNetworkInfo();
            if (ni == null || !ni.isConnected()) return null;
            return ni.getType() == 1 ? "Wi-Fi" : ni.getType() == 0 ? "SIM" : "network";
        } catch (Throwable t) { return null; }
    }
    void setStopped(boolean st) { stopped = st; a.prefs.edit().putBoolean("dlStop", st).apply(); }
    boolean loadingNow() { return !finished && !full && !stopped && !paused && System.currentTimeMillis() - lastOk < 8000; }

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
            c.setRequestProperty("User-Agent", "CarlinBox/2.07");
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
