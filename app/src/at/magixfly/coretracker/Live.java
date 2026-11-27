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

    /** V2.62: Overpass with fallback servers (overpass-api.de answered 406 from the box) + log for diagnosis */
    static final String[] OVP = {"https://overpass-api.de/api/interpreter", "https://maps.mail.ru/osm/tools/overpass/api/interpreter", "https://overpass.private.coffee/api/interpreter"};
    static int ovpGood = 1;   // V2.70: mail.ru first (overpass-api.de refuses the box)
    static byte[] overpass(String q, int to, String what) throws Exception {
        String e = java.net.URLEncoder.encode(q, "UTF-8");
        for (int k = 0; k < OVP.length; k++) {
            int i = (ovpGood + k) % OVP.length;
            long t0 = System.currentTimeMillis();
            byte[] d = TileStore.http(OVP[i] + "?data=" + e, to);
            boolean ok = d != null && d.length > 50 && new String(d, 0, Math.min(d.length, 3000), "UTF-8").contains("\"elements\"");   // V2.70: the header is longer than 200 B
            android.util.Log.d("CTLIVE", what + " " + OVP[i] + " -> " + (d == null ? "null" : d.length + " B") + (ok ? " ok" : " BAD") + " " + (System.currentTimeMillis() - t0) + " ms");
            if (ok) { ovpGood = i; return d; }
        }
        return null;
    }

    static synchronized byte[] radars(MainActivity a) {
        File f = new File(a.getFilesDir(), "radars.json");
        if (f.exists() && f.length() > 100 && System.currentTimeMillis() - f.lastModified() < 86400000L) return TileStore.read(f);
        try {
            String q = "[out:json][timeout:90];area[\"ISO3166-1\"=\"AT\"][admin_level=2]->.a;(node[\"highway\"=\"speed_camera\"](area.a););out body;";
            byte[] d = overpass(q, 90000, "radars");
            if (d != null && d.length > 100) { TileStore.save(f, d); return d; }
        } catch (Throwable t) { android.util.Log.d("CTLIVE", "radars: " + t); }
        return f.exists() ? TileStore.read(f) : null;
    }

    /** V2.32: roads around the position from OpenStreetMap (speed limits) - Overpass, ways with geometry */
    static byte[] roads(double lat, double lon) {
        try {
            String q = "[out:json][timeout:12];way(around:550," + lat + "," + lon + ")[highway~\"^(motorway|motorway_link|trunk|trunk_link|primary|primary_link|secondary|secondary_link|tertiary|tertiary_link|unclassified|residential|living_street|road)$\"];out tags geom;";
            return overpass(q, 15000, "roads");
        } catch (Throwable t) { return null; }
    }

    /** V2.33: place name -> coordinates (Nominatim, Austria) for the traffic messages, which have no coordinates */
    static byte[] geo(String q) {
        try {
            java.net.HttpURLConnection c = (java.net.HttpURLConnection) new java.net.URL("https://nominatim.openstreetmap.org/search?format=json&limit=1&countrycodes=at&q=" + java.net.URLEncoder.encode(q, "UTF-8")).openConnection();
            c.setConnectTimeout(8000); c.setReadTimeout(8000); c.setRequestProperty("User-Agent", "CarlinBox/2.33 (private car display)");
            if (c.getResponseCode() != 200) return null;
            java.io.InputStream in = c.getInputStream(); java.io.ByteArrayOutputStream o = new java.io.ByteArrayOutputStream(); byte[] b = new byte[8192]; int n;
            while ((n = in.read(b)) > 0) o.write(b, 0, n); in.close(); return o.toByteArray();
        } catch (Throwable t) { return null; }
    }
}
