package at.magixfly.coretracker;

import android.app.Activity;
import android.content.SharedPreferences;
import android.os.Bundle;
import android.os.Handler;
import android.os.Looper;
import android.webkit.WebSettings;
import android.webkit.WebView;
import android.widget.FrameLayout;

/**
 * V2.06: Karten nach der gemeinsamen Gebietsliste (gebiete.json), Tracker-ESP über Bluetooth (MT12-Telemetrie des Mojave).
 * V2.01: Carlin Box – eigenständig, ohne Core Tracker (Wunsch Thorsten 24.11.).
 * Startseite = eigene Offline-Karte Wien + NÖ aus dem Box-Speicher (Leaflet, in der App mitgeliefert),
 * eigene Position über das GPS der Box (falls vorhanden), FPV vom CosmoStreamer, WLAN/Hotspot-Anzeige.
 * Kein Pi, keine Pi-Suche, kein Tracker auf der Box, kein Bluetooth-ESP, kein Status an den Pi.
 */
public class MainActivity extends Activity {
    static final String HOST = "http://box.local/";    // wird komplett in Client.shouldInterceptRequest beantwortet

    WebView web;
    Handler ui;
    SharedPreferences prefs;
    TileStore tiles;
    Fpv fpv;
    Gps gps;
    volatile boolean loaded = false;

    /** V1.75: App schließen bzw. neu starten (Menü) */
    static void quit(android.app.Activity a, boolean restart) {
        if (restart) {
            try {
                android.content.Intent i = new android.content.Intent(a, MainActivity.class).addFlags(android.content.Intent.FLAG_ACTIVITY_NEW_TASK | android.content.Intent.FLAG_ACTIVITY_CLEAR_TASK);
                android.app.PendingIntent pi = android.app.PendingIntent.getActivity(a, 9, i, 0x04000000 | 0x08000000);   // IMMUTABLE | CANCEL_CURRENT
                ((android.app.AlarmManager) a.getSystemService(ALARM_SERVICE)).set(android.app.AlarmManager.RTC, System.currentTimeMillis() + 800, pi);
            } catch (Throwable t) { android.util.Log.d("CTAP", "restart: " + t); }
        }
        a.finishAndRemoveTask();
        if (restart) android.os.Process.killProcess(android.os.Process.myPid());
    }

    static String ver(android.content.Context c) { try { return c.getPackageManager().getPackageInfo(c.getPackageName(), 0).versionName; } catch (Throwable t) { return "?"; } }

    static volatile boolean alive = false;   // V1.59: Karte läuft (für die Rückkehr nach dem Hotspot-Schalten)
    @Override protected void onDestroy() { alive = false; if (gps != null) gps.stop(); super.onDestroy(); }

    static volatile MainActivity me;   // 2.10: for the remote page (mouse wheel)
    /** V2.16: answer from the package installer - without root (car hotspot, no ADB) Android asks "Install?" -> show it, A11y taps it */
    void instAntwort(android.content.Intent i) {
        try {
            if (i == null) return;
            int st = i.getIntExtra(android.content.pm.PackageInstaller.EXTRA_STATUS, -999);
            if (st == -999) return;
            if (st == android.content.pm.PackageInstaller.STATUS_PENDING_USER_ACTION) {
                android.content.Intent c = (android.content.Intent) i.getParcelableExtra(android.content.Intent.EXTRA_INTENT);
                if (c != null) { c.addFlags(android.content.Intent.FLAG_ACTIVITY_NEW_TASK); A11y.want("inst"); startActivity(c); }
            } else if (st != android.content.pm.PackageInstaller.STATUS_SUCCESS) {
                Updater.st = "Update failed: " + i.getStringExtra(android.content.pm.PackageInstaller.EXTRA_STATUS_MESSAGE); Updater.pct = -1;
            }
        } catch (Throwable t) { android.util.Log.d("CTAP", "inst: " + t); }
    }
    @Override protected void onNewIntent(android.content.Intent i) { super.onNewIntent(i); instAntwort(i); }

    @Override
    protected void onCreate(Bundle b) {
        super.onCreate(b);
        me = this;
        alive = true;
        instAntwort(getIntent());
        ScreenShare.server(this);                 // V1.65: Box-Bildschirm im Browser (Port 8090)
        requestWindowFeature(1);                  // kein Titelbalken
        getWindow().addFlags(0x80 | 0x400);       // Bildschirm an lassen + Vollbild
        ui = new Handler(Looper.getMainLooper());
        prefs = getSharedPreferences("ct", 0);

        FrameLayout root = new FrameLayout(this);
        root.setBackgroundColor(0xFF0B0F14);

        tiles = TileStore.get(this);   // V2.64: maybe already running since power-on
        web = new WebView(this);
        WebSettings s = web.getSettings();
        s.setJavaScriptEnabled(true);
        s.setDomStorageEnabled(true);
        s.setMediaPlaybackRequiresUserGesture(false);
        s.setTextZoom(100);
        s.setCacheMode(WebSettings.LOAD_NO_CACHE);   // Kacheln kommen ohnehin aus dem Box-Speicher
        web.setBackgroundColor(0xFF0B0F14);
        web.setWebViewClient(new Client(this));
        root.addView(web, new FrameLayout.LayoutParams(-1, -1, 17));

        fpv = new Fpv(this, root);                // V1.26: FPV vom CosmoStreamer (Knopf links unten)
        setContentView(root);
        AdbWifi.ensure(this);
        HotspotBoot.maybe(this);                  // V1.39: WLAN-Reihenfolge / Hotspot nach dem Start
        A11y.enable(this);
        Updater.loop(this);                       // V1.52: Selbst-Update von GitHub
        web.loadUrl(HOST);
        gps = new Gps(this);
        gps.start();
        BleEsp.start(this);                       // V2.06: Tracker-ESP über Bluetooth (MT12-Telemetrie des Mojave + GPS)
        new Thread(new Runnable() { public void run() { netLoop(); } }).start();   // V1.43: WLAN/Hotspot der Box anzeigen
        ui.postDelayed(new Runnable() { public void run() { tick(); } }, 1000);
        hideBars();
    }

    void hideBars() {
        try { getWindow().getDecorView().setSystemUiVisibility(0x1706); } catch (Throwable t) { }
    }

    @Override
    protected void onResume() { super.onResume(); hideBars();
        try { if (web != null) web.onResume(); if (fpv != null && fpv.web != null) fpv.web.onResume(); } catch (Throwable t) { } }
    @Override protected void onPause() { super.onPause();
        try { if (web != null) web.onPause(); if (fpv != null && fpv.web != null) fpv.web.onPause(); } catch (Throwable t) { } }   // Kartendownload läuft im Hintergrund weiter

    @Override
    public void onWindowFocusChanged(boolean f) { super.onWindowFocusChanged(f); if (f) hideBars(); }

    @Override
    public void onBackPressed() {
        if (fpv != null && fpv.mode != Fpv.MAP) { fpv.setMode(Fpv.MAP); return; }
        super.onBackPressed();
    }

    void js(final String s) { ui.post(new Runnable() { public void run() { if (loaded && web != null) web.evaluateJavascript(s, null); } }); }

    int ticks = 0;
    /** jede Sekunde: Kartendownload-Status (mit Prozent für den Balken) an die Seite */
    void tick() {
        try { updatePill(); if ((++ticks % 30) == 0) tiles.saveTotal(); } catch (Throwable t) { }
        if (ticks % 60 == 5) new Thread() { public void run() { Track.check(MainActivity.this); } }.start();   // V2.55: finish drives, upload GPX
        ui.postDelayed(new Runnable() { public void run() { tick(); } }, 1000);
    }

    static String size(long b) { return b >= 1073741824L ? String.format(java.util.Locale.US, "%.1f GB", b / 1073741824.0) : (b / 1048576) + " MB"; }

    void updatePill() {
        if (!loaded) return;
        long b1 = tiles.bytes.get(), b2 = tiles.estimate();
        String mb = (b1 >= 1073741824L && b2 >= 1073741824L) ? String.format(java.util.Locale.US, "%.1f/%.1f GB", b1 / 1073741824.0, b2 / 1073741824.0) : size(b1) + "/" + size(b2);
        boolean on = tiles.loadingNow() || "cleaning".equals(tiles.phase);
        String st = tiles.stateText();
        int pct = tiles.finished && !"cleaning".equals(tiles.phase) ? 100 : tiles.percent();
        web.evaluateJavascript("window.ctUpd&&ctUpd(" + Client.q(Updater.st) + "," + Updater.pct + ")", null);
        web.evaluateJavascript("window.ctMaps&&ctMaps(" + pct + "," + Client.q(mb) + "," + Client.q(st) + "," + (on ? 1 : 0) + ")", null);
    }

    volatile String netTxt = "";
    /** V1.43: WLAN der Box bzw. „Hotspot“ (über die lokale Root-Shell, alle 15 s). Prüft dabei auch ADB über WLAN (Fernwartung). */
    /** 2.51: wifi = Wi-Fi, phone = Wi-Fi that is a phone hotspot (metered), ap = own hotspot (+ ",lte" when the SIM carries it), lte = SIM only, none */
    String netTyp() {
        boolean wifi = false, cell = false, metered = false;
        try {
            android.net.ConnectivityManager cm = (android.net.ConnectivityManager) getSystemService(CONNECTIVITY_SERVICE);
            for (android.net.Network nw : cm.getAllNetworks()) {
                android.net.NetworkCapabilities nc = cm.getNetworkCapabilities(nw);
                if (nc == null || !nc.hasCapability(android.net.NetworkCapabilities.NET_CAPABILITY_INTERNET)) continue;
                if (nc.hasTransport(android.net.NetworkCapabilities.TRANSPORT_WIFI)) { wifi = true; metered = !nc.hasCapability(android.net.NetworkCapabilities.NET_CAPABILITY_NOT_METERED); }
                if (nc.hasTransport(android.net.NetworkCapabilities.TRANSPORT_CELLULAR)) cell = true;
            }
        } catch (Throwable t) { }
        if (wifi) return metered ? "phone" : "wifi";
        if (HotspotBoot.apOn(this)) return cell ? "ap,lte" : "ap";
        return cell ? "lte" : "none";
    }

    void netLoop() {
        int n = 0;
        while (true) {
            try {
                String sw = wifiTxt();
                if (HotspotBoot.apOn(this) && ("Box: SIM".equals(sw) || "Box: ?".equals(sw))) { netTxt = "Hotspot" + apBand(); throw new RuntimeException("ap"); }
                String r = HotspotBoot.shell("dumpsys tethering | grep -c TetheredState; cmd wifi status | grep -m1 'connected to'");
                String[] l = r.split("\n");
                int teth = 0; try { teth = Integer.parseInt(l[0].trim()); } catch (Throwable t) { }
                java.util.regex.Matcher w0 = java.util.regex.Pattern.compile("connected to \"([^\"]*)\"").matcher(r);
                if (w0.find()) netTxt = w0.group(1) + " " + ghz();
                else if (teth > 0 && HotspotBoot.apOn(this)) netTxt = "Hotspot" + apBand();
                else netTxt = "no Wi-Fi";
            } catch (Throwable e) { if (!"ap".equals(e.getMessage())) netTxt = wifiTxt().replace("Box: ", ""); }
            netTxt = netTyp() + "|" + netTxt.replace("|", " ");   // 2.51: connection type for the icon (wifi / phone hotspot / own hotspot / LTE)
            js("window.ctNet&&ctNet(" + Client.q(netTxt) + ")");
            if ((++n % 2) == 0 && prefs.getBoolean("adbAuto", true)) AdbWifi.ensure(this);   // alle 30 s
            if ((n % 4) == 0) roam();                                                           // V2.03: alle 60 s
            try { Thread.sleep(15000); } catch (Throwable e) { }
        }
    }

    /** V2.03: mehrere Zugangspunkte mit demselben WLAN-Namen (z. B. „Media“): ist ein anderer mindestens 10 dB stärker, dorthin wechseln. */
    void roam() {
        try {
            String r = HotspotBoot.shell("cmd wifi status | grep -m1 'WifiInfo'; wpa_cli -i wlan0 scan_results");
            java.util.regex.Matcher m = java.util.regex.Pattern.compile("SSID: \"([^\"]*)\", BSSID: ([0-9a-f:]{17}).*?RSSI: (-?\\d+)").matcher(r);
            if (!m.find()) return;
            String ssid = m.group(1), cur = m.group(2); int rssi = Integer.parseInt(m.group(3));
            String best = null; int bestR = -200;
            for (String l : r.split("\n")) {
                String[] p = l.split("\t");
                if (p.length < 5 || !p[4].equals(ssid)) continue;
                int sg; try { sg = Integer.parseInt(p[2].trim()); } catch (Throwable t) { continue; }
                if (sg > bestR) { bestR = sg; best = p[0].trim(); }
            }
            android.util.Log.d("CTWLAN", ssid + " cur " + cur + " " + rssi + " best " + best + " " + bestR);
            if (best != null && !best.equals(cur) && bestR >= rssi + 10) {
                android.util.Log.d("CTWLAN", "roam -> " + best);
                HotspotBoot.shell("wpa_cli -i wlan0 roam " + best);
            }
        } catch (Throwable t) { android.util.Log.d("CTWLAN", "roam: " + t); }
    }

    /** V1.56: Band + Signal des WLANs, mit dem die Box verbunden ist */
    String ghz() {
        try {
            android.net.wifi.WifiManager wm = (android.net.wifi.WifiManager) getApplicationContext().getSystemService(WIFI_SERVICE);
            android.net.wifi.WifiInfo wi = wm.getConnectionInfo();
            int f = wi.getFrequency(), r = wi.getRssi();
            return (f > 4900 ? "5 GHz" : f > 2000 ? "2.4 GHz" : "") + (r < 0 && r > -127 ? " · " + r + " dBm" : "");
        } catch (Throwable t) { return ""; }
    }
    /** V1.56: Band des eigenen Hotspots (alte und neue Android-API per Reflection) */
    String apBand() {
        try {
            Object wm = getApplicationContext().getSystemService(WIFI_SERVICE);
            try {
                Object c = wm.getClass().getMethod("getSoftApConfiguration").invoke(wm);
                int b = (Integer) c.getClass().getMethod("getBand").invoke(c);
                return (b & 2) != 0 && (b & 1) == 0 ? " 5 GHz" : (b & 1) != 0 && (b & 2) == 0 ? " 2.4 GHz" : (b & 3) == 3 ? " 2.4/5" : "";
            } catch (NoSuchMethodException e) { }
            Object c = wm.getClass().getMethod("getWifiApConfiguration").invoke(wm);
            int b = c.getClass().getField("apBand").getInt(c);
            return b == 1 ? " 5 GHz" : b == 0 ? " 2.4 GHz" : "";
        } catch (Throwable t) { return ""; }
    }

    String wifiTxt() {
        try {
            android.net.wifi.WifiManager wm = (android.net.wifi.WifiManager) getApplicationContext().getSystemService(WIFI_SERVICE);
            android.net.wifi.WifiInfo wi = wm.getConnectionInfo();
            if (wi == null || wi.getNetworkId() == -1) return "Box: SIM";
            String ss = wi.getSSID(); if (ss == null || ss.contains("unknown")) ss = "Wi-Fi"; ss = ss.replace("\"", "");
            return "Box: " + ss + " " + ghz();
        } catch (Throwable t) { return "Box: ?"; }
    }
}
