package at.magixfly.coretracker;

import java.util.HashSet;
import org.json.JSONArray;
import org.json.JSONObject;

/**
 * V2.06: gemeinsame Gebietsliste (gebiete.json) für Core, Tracker, Box und Navi (Plan Kartenabgleich 24.11.).
 * Rechnet die Kacheln aus: für jedes Gebiet z = zmin … min(zmax, map_zmax der Box).
 * rect = Kachel-Bbox, circle = Kachel, deren nächster Punkt ≤ r vom Mittelpunkt, route = Linie mind. alle halbe Kachel abtasten, je Punkt Bbox ±w.
 */
class Areas {
    final JSONObject json;
    final int ver, zmin, zcap;
    final HashSet<Long> want = new HashSet<Long>();
    final java.util.HashMap<Long, Long> prio = new java.util.HashMap<Long, Long>();   // V2.14: "load first" areas (prio from the PC editor)
    int zmaxAll = 0;

    static long key(int z, long x, long y) { return ((long) z << 56) | (x << 28) | y; }

    Areas(JSONObject j, int zcap) throws Exception {
        json = j;
        ver = j.optInt("ver", 0);
        zmin = j.optInt("zmin", 8);
        this.zcap = zcap;
        JSONArray a = j.getJSONArray("areas");
        for (int i = 0; i < a.length(); i++) {
            JSONObject o = a.getJSONObject(i);
            int zm = Math.min(o.optInt("zmax", 16), zcap);
            zmaxAll = Math.max(zmaxAll, zm);
            long pr = o.optLong("prio", 0);
            if (pr > 0) {   // V2.14: remember which tiles belong to a "load first" area
                HashSet<Long> vor = new HashSet<Long>(want); want.clear();
                for (int z = zmin; z <= zm; z++) add(o, z);
                for (Long k : want) { Long p0 = prio.get(k); if (p0 == null || p0 < pr) prio.put(k, pr); }
                want.addAll(vor);
            } else for (int z = zmin; z <= zm; z++) add(o, z);
        }
    }

    boolean has(int z, long x, long y) { return want.contains(key(z, x, y)); }

    void box(int z, double s, double n, double w, double e) {
        long x0 = TileStore.lonX(w, z), x1 = TileStore.lonX(e, z), y0 = TileStore.latY(n, z), y1 = TileStore.latY(s, z);
        for (long x = x0; x <= x1; x++) for (long y = y0; y <= y1; y++) want.add(key(z, x, y));
    }

    static double lonOf(long x, int z) { return x / (double) (1L << z) * 360.0 - 180.0; }
    static double latOf(long y, int z) { double n = Math.PI * (1 - 2.0 * y / (1L << z)); return Math.toDegrees(Math.atan(Math.sinh(n))); }

    static double dist(double la1, double lo1, double la2, double lo2) {
        double r = 6371000, p1 = Math.toRadians(la1), p2 = Math.toRadians(la2), dp = p2 - p1, dl = Math.toRadians(lo2 - lo1);
        double h = Math.sin(dp / 2) * Math.sin(dp / 2) + Math.cos(p1) * Math.cos(p2) * Math.sin(dl / 2) * Math.sin(dl / 2);
        return 2 * r * Math.asin(Math.min(1, Math.sqrt(h)));
    }

    void add(JSONObject o, int z) throws Exception {
        String t = o.optString("type");
        if (t.equals("rect")) {
            box(z, o.getDouble("s"), o.getDouble("n"), o.getDouble("w"), o.getDouble("e"));
        } else if (t.equals("circle")) {
            double la = o.getDouble("lat"), lo = o.getDouble("lon"), r = o.getDouble("r");
            double dla = r / 111320.0, dlo = r / (111320.0 * Math.cos(Math.toRadians(la)));
            long x0 = TileStore.lonX(lo - dlo, z), x1 = TileStore.lonX(lo + dlo, z), y0 = TileStore.latY(la + dla, z), y1 = TileStore.latY(la - dla, z);
            for (long x = x0; x <= x1; x++) for (long y = y0; y <= y1; y++) {
                double lo0 = lonOf(x, z), lo1 = lonOf(x + 1, z), la1 = latOf(y, z), la0 = latOf(y + 1, z);
                double cla = Math.min(Math.max(la, la0), la1), clo = Math.min(Math.max(lo, lo0), lo1);   // nächster Punkt der Kachel
                if (dist(la, lo, cla, clo) <= r) want.add(key(z, x, y));
            }
        } else if (t.equals("route")) {
            double w = o.optDouble("w", 2000);
            double step = Math.max(50, Math.min(w, 40075000.0 / (1L << z) / 2));
            JSONArray p = o.getJSONArray("pts");
            for (int i = 0; i + 1 < p.length(); i++) {
                double la0 = p.getJSONArray(i).getDouble(0), lo0 = p.getJSONArray(i).getDouble(1);
                double la1 = p.getJSONArray(i + 1).getDouble(0), lo1 = p.getJSONArray(i + 1).getDouble(1);
                int k = Math.max(1, (int) (dist(la0, lo0, la1, lo1) / step));
                for (int j = 0; j <= k; j++) {
                    double la = la0 + (la1 - la0) * j / k, lo = lo0 + (lo1 - lo0) * j / k;
                    double dla = w / 111320.0, dlo = w / (111320.0 * Math.cos(Math.toRadians(la)));
                    box(z, la - dla, la + dla, lo - dlo, lo + dlo);
                }
            }
        }
    }

    /** liegt der Punkt in einem Gebiet? (geprüft über die Kachel in Zoom 16 bzw. der kleinsten gemeinsamen Stufe) */
    boolean covers(double lat, double lon) {
        int z = Math.min(16, zmaxAll);
        return has(z, TileStore.lonX(lon, z), TileStore.latY(lat, z));
    }
}
