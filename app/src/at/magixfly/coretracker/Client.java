package at.magixfly.coretracker;
import android.webkit.WebResourceRequest;
import android.webkit.WebResourceResponse;
import android.webkit.WebView;
import android.webkit.WebViewClient;
import java.io.ByteArrayInputStream;

/** V2.01: beantwortet die ganze Kartenseite selbst (http://box.local/…): Seite, Leaflet, Kacheln aus dem Box-Speicher, Menü-Befehle. */
class Client extends WebViewClient {
    final MainActivity a;
    Client(MainActivity a) { this.a = a; }

    static String q(String s) { return s == null ? "null" : org.json.JSONObject.quote(s); }

    @Override
    public void onPageFinished(WebView v, String url) {
        a.loaded = true;
        v.evaluateJavascript("window.ctInit&&ctInit(" + q(MainActivity.ver(a)) + "," + TileStore.C_LAT + "," + TileStore.C_LON + "," + a.prefs.getBoolean("ble", true) + ")", null);
        if (a.gps != null) a.gps.push();
        a.updatePill();
        a.js("window.ctNet&&ctNet(" + q(a.netTxt) + ")");
    }

    static WebResourceResponse empty(int code) {
        return new WebResourceResponse("text/plain", "utf-8", code, code == 200 ? "OK" : "Not Found", null, new ByteArrayInputStream(new byte[0]));
    }
    WebResourceResponse raw(String name, String mime) {
        int id = a.getResources().getIdentifier(name, "raw", a.getPackageName());
        return new WebResourceResponse(mime, "utf-8", a.getResources().openRawResource(id));
    }

    @Override
    public WebResourceResponse shouldInterceptRequest(WebView v, WebResourceRequest r) {
        String url = r.getUrl().toString();
        if (!url.startsWith(MainActivity.HOST)) return null;
        String p = url.substring(MainActivity.HOST.length());
        int qi = p.indexOf('?'); if (qi >= 0) p = p.substring(0, qi);
        try {
            if (p.isEmpty() || p.equals("index.html")) return raw("map", "text/html");
            if (p.equals("leaflet.js")) return raw("leaflet", "application/javascript");
            if (p.equals("leaflet.css")) return raw("leaflet_css", "text/css");
            if (p.equals("__ctbox/areas")) {                                             // V2.07: Gebietsliste für den Knopf AREAS
                byte[] d = a.tiles.listFile.exists() ? TileStore.read(a.tiles.listFile) : null;
                if (d == null) return empty(404);
                return new WebResourceResponse("application/json", "utf-8", new ByteArrayInputStream(d));
            }
            if (p.equals("__ctbox/traffic")) { byte[] d = Live.traffic(); return d == null ? empty(503) : new WebResourceResponse("application/xml", "utf-8", new ByteArrayInputStream(d)); }   // V2.30
            if (p.equals("__ctbox/roads")) {   // V2.32: speed limits around the position
                android.net.Uri u = r.getUrl(); double la = Double.parseDouble(u.getQueryParameter("lat")), lo = Double.parseDouble(u.getQueryParameter("lon"));
                byte[] d = Live.roads(la, lo); return d == null || d.length == 0 ? empty(503) : new WebResourceResponse("application/json", "utf-8", new ByteArrayInputStream(d)); }
            if (p.equals("__ctbox/geo")) { byte[] d = Live.geo(r.getUrl().getQueryParameter("q")); return d == null ? empty(503) : new WebResourceResponse("application/json", "utf-8", new ByteArrayInputStream(d)); }   // V2.33
            if (p.equals("__ctbox/radars")) { byte[] d = Live.radars(a); return d == null ? empty(503) : new WebResourceResponse("application/json", "utf-8", new ByteArrayInputStream(d)); }   // V2.30
            if (p.startsWith("__ctbox/")) {
                String c = p.substring(8);
                if (c.equals("toggle")) a.tiles.setStopped(!a.tiles.stopped);           // V1.22: Tippen auf „Maps“ = Download Stopp/Start
                else if (c.equals("update")) Updater.now(a);                            // V2.06: Knopf „Check for update“ (fehlte in 2.05)
                else if (c.equals("ble")) { boolean on = !a.prefs.getBoolean("ble", true); a.prefs.edit().putBoolean("ble", on).apply();   // V2.06: Bluetooth ein/aus (wirkt nach Neustart)
                    a.ui.postDelayed(new Runnable() { public void run() { MainActivity.quit(a, true); } }, 300); }
                else if (c.equals("restart") || c.equals("close")) {                    // V1.75: App neu starten / schließen
                    final boolean re = c.equals("restart");
                    a.ui.postDelayed(new Runnable() { public void run() { MainActivity.quit(a, re); } }, 200);
                } else if (c.equals("autostart"))
                    a.startActivity(new android.content.Intent(a, Autostart.class).addFlags(android.content.Intent.FLAG_ACTIVITY_NEW_TASK));
                a.ui.post(new Runnable() { public void run() { a.updatePill(); } });
                return empty(200);
            }
            boolean ovl = p.startsWith("ovl/");
            if (p.startsWith("tile/") || ovl) {
                String[] s = p.substring(ovl ? 4 : 5).split("[/.]");
                byte[] d = a.tiles.get(Integer.parseInt(s[0]), Integer.parseInt(s[1]), Integer.parseInt(s[2]), ovl);
                if (d == null || d.length == 0) return empty(404);
                return new WebResourceResponse(ovl ? "image/png" : "image/jpeg", null, new ByteArrayInputStream(d));
            }
        } catch (Throwable t) { android.util.Log.d("CTAP", "intercept " + p + ": " + t); }
        return empty(404);
    }
}
