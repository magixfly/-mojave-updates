package at.magixfly.coretracker;

import java.io.File;

/** V2.30: live information for the map - ASFINAG traffic messages (motorways, Atom feed, no coordinates) and fixed speed cameras from OpenStreetMap (Austria, checked once a day). */
class Live {
    static byte[] tr; static long trT;

    static synchronized byte[] traffic() {
        long n = System.currentTimeMillis();
        if (tr != null && n - trT < 120000) return tr;
        byte[] d = TileStore.http("https://publiccontent.asfinag.at/rss/feed/de/trafficmessages", 8000);
        if (d != null && d.length > 0) { tr = d; trT = n; }
        return tr;
    }

    static synchronized byte[] radars(MainActivity a) {
        File f = new File(a.getFilesDir(), "radars.json");
        if (f.exists() && f.length() > 100 && System.currentTimeMillis() - f.lastModified() < 86400000L) return TileStore.read(f);
        try {
            String q = "[out:json][timeout:90];area[\"ISO3166-1\"=\"AT\"][admin_level=2]->.a;(node[\"highway\"=\"speed_camera\"](area.a););out body;";
            byte[] d = TileStore.http("https://overpass-api.de/api/interpreter?data=" + java.net.URLEncoder.encode(q, "UTF-8"), 90000);
            if (d != null && d.length > 100) { TileStore.save(f, d); return d; }
        } catch (Throwable t) { android.util.Log.d("CTLIVE", "radars: " + t); }
        return f.exists() ? TileStore.read(f) : null;
    }
}
