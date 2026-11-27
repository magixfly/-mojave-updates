package at.magixfly.coretracker;

import android.content.Context;
import java.io.File;
import java.io.FileOutputStream;
import java.text.SimpleDateFormat;
import java.util.Date;
import java.util.Locale;

/** V2.55: drive recording. The map sends points (lat,lon,kmh,unixtime;...), they go to tracks/cur.csv.
 *  A gap of 10 min ends the drive: cur.csv becomes YYYY-MM-DD_HHMM.gpx and is uploaded to GitHub tracks/ (the PC map program fetches it). */
class Track {
    static final long GAP = 600;   // s
    static long lastT = 0;
    static Thread up = null;

    static File dir(Context c) { File d = new File(c.getFilesDir(), "tracks"); d.mkdirs(); return d; }

    static synchronized void add(Context c, String data) {
        try {
            File cur = new File(dir(c), "cur.csv");
            if (lastT == 0 && cur.exists()) lastT = lastTime(cur);
            StringBuilder sb = new StringBuilder();
            for (String p : data.split(";")) {
                String[] f = p.split(",");
                if (f.length < 4) continue;
                long t = Long.parseLong(f[3].trim());
                if (lastT > 0 && t - lastT > GAP && cur.exists()) { flush(cur, sb); finish(c); }
                lastT = t;
                sb.append(f[0]).append(',').append(f[1]).append(',').append(f[2]).append(',').append(t).append('\n');
            }
            flush(cur, sb);
        } catch (Throwable t) { android.util.Log.d("CTTRK", "add: " + t); }
        upload(c);
    }

    static void flush(File cur, StringBuilder sb) throws Exception {
        if (sb.length() == 0) return;
        FileOutputStream o = new FileOutputStream(cur, true); o.write(sb.toString().getBytes("UTF-8")); o.close(); sb.setLength(0);
    }

    static long lastTime(File f) {
        try { String[] l = new String(TileStore.read(f), "UTF-8").trim().split("\n"); String[] x = l[l.length - 1].split(","); return Long.parseLong(x[3]); } catch (Throwable t) { return 0; }
    }

    /** called on app start and every minute: a drive that ended more than 10 min ago becomes a GPX file */
    static synchronized void check(Context c) {
        File cur = new File(dir(c), "cur.csv");
        if (cur.exists() && System.currentTimeMillis() / 1000 - lastTime(cur) > GAP) finish(c);
        upload(c);
    }

    static void finish(Context c) {
        File cur = new File(dir(c), "cur.csv");
        try {
            String[] l = new String(TileStore.read(cur), "UTF-8").trim().split("\n");
            if (l.length >= 20) {
                long t0 = Long.parseLong(l[0].split(",")[3]);
                SimpleDateFormat iso = new SimpleDateFormat("yyyy-MM-dd'T'HH:mm:ss'Z'", Locale.US); iso.setTimeZone(java.util.TimeZone.getTimeZone("UTC"));
                String name = new SimpleDateFormat("yyyy-MM-dd_HHmm", Locale.US).format(new Date(t0 * 1000)) + ".gpx";
                StringBuilder g = new StringBuilder("<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n<gpx version=\"1.1\" creator=\"Core Dash\" xmlns=\"http://www.topografix.com/GPX/1/1\">\n<trk><name>"
                        + name.replace(".gpx", "") + "</name><trkseg>\n");
                for (String s : l) {
                    String[] f = s.split(",");
                    if (f.length < 4) continue;
                    g.append("<trkpt lat=\"").append(f[0]).append("\" lon=\"").append(f[1]).append("\"><time>").append(iso.format(new Date(Long.parseLong(f[3]) * 1000)))
                     .append("</time><extensions><kmh>").append(f[2]).append("</kmh></extensions></trkpt>\n");
                }
                g.append("</trkseg></trk>\n</gpx>\n");
                TileStore.save(new File(dir(c), name), g.toString().getBytes("UTF-8"));
            }
        } catch (Throwable t) { android.util.Log.d("CTTRK", "finish: " + t); }
        cur.delete(); lastT = 0;
    }

    /** uploads finished GPX files that are not on GitHub yet (marker file name.up) */
    static synchronized void upload(final Context c) {
        if (up != null && up.isAlive()) return;
        up = new Thread() { public void run() {
            for (File f : dir(c).listFiles()) {
                if (!f.getName().endsWith(".gpx")) continue;
                File m = new File(f.getPath() + ".up");
                if (m.exists()) continue;
                try { BoxBridge.put(c, "tracks/" + f.getName(), TileStore.read(f), "Box track " + f.getName()); m.createNewFile(); }
                catch (Throwable t) { android.util.Log.d("CTTRK", "upload: " + t); return; }
            }
        } };
        up.start();
    }
}
