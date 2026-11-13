package at.magixfly.coretracker;

import android.app.Activity;
import android.content.SharedPreferences;
import android.os.Bundle;
import android.os.Handler;
import android.os.Looper;
import android.view.View;
import android.view.ViewGroup;
import android.webkit.WebSettings;
import android.webkit.WebView;
import android.webkit.WebViewClient;
import android.widget.FrameLayout;
import android.widget.LinearLayout;
import android.widget.TextView;

import java.net.HttpURLConnection;
import java.net.URL;
import java.util.ArrayList;
import java.util.List;

/**
 * Core Tracker für die CarlinKit-Box: zeigt die Tracker-Seite des Pi (Port 8080) im Vollbild.
 * Sucht den Pi automatisch (corepi.local, letzte Adresse, Hotspot-Adressen) mit Fortschrittsanzeige.
 */
public class MainActivity extends Activity {
    static final int PORT = 8080;
    static final String[] FIXED = {"corepi.local", "172.20.10.2", "10.42.0.1", "192.168.4.1"};

    WebView web;
    LinearLayout overlay;
    TextView status;
    TextView bar;
    LinearLayout barBox;
    Handler ui;
    SharedPreferences prefs;
    TileStore tiles;
    MojaveView mojave;
    TextView pillText;
    LinearLayout pill;
    volatile String piBase = null;
    volatile boolean searching = false;
    volatile boolean loaded = false;
    int barWidthPx = 600;

    @Override
    protected void onCreate(Bundle b) {
        super.onCreate(b);
        requestWindowFeature(1);                  // kein Titelbalken
        getWindow().addFlags(0x80 | 0x400);       // Bildschirm an lassen + Vollbild
        ui = new Handler(Looper.getMainLooper());
        prefs = getSharedPreferences("ct", 0);

        FrameLayout root = new FrameLayout(this);
        root.setBackgroundColor(0xFF0B0F14);

        web = new WebView(this);
        WebSettings s = web.getSettings();
        s.setJavaScriptEnabled(true);
        s.setDomStorageEnabled(true);
        s.setMediaPlaybackRequiresUserGesture(false);
        s.setUseWideViewPort(true);          // Seite so breit wie in Chrome darstellen
        s.setLoadWithOverviewMode(true);
        s.setTextZoom(100);                  // Schriftgröße wie in Chrome
        s.setCacheMode(-1);                  // Standard-Cache (Kartenkacheln bleiben gespeichert)
        web.setBackgroundColor(0xFF0B0F14);
        web.setWebViewClient(new Client(this));
        root.addView(web, new FrameLayout.LayoutParams(-1, -1, 17));

        overlay = new LinearLayout(this);
        overlay.setOrientation(1);
        overlay.setGravity(17);
        overlay.setBackgroundColor(0xFF0B0F14);

        TextView title = new TextView(this);
        title.setText("CORE TRACKER");
        title.setTextSize(34);
        title.setTextColor(0xFF4ADE80);
        title.setGravity(17);
        overlay.addView(title);

        status = new TextView(this);
        status.setTextSize(20);
        status.setTextColor(0xFFE5E7EB);
        status.setGravity(17);
        status.setPadding(0, 30, 0, 30);
        overlay.addView(status);

        // Ladebalken mit Prozent darin
        barBox = new LinearLayout(this);
        barBox.setBackgroundColor(0xFF1F2937);
        bar = new TextView(this);
        bar.setBackgroundColor(0xFF22C55E);
        bar.setTextColor(0xFF0B0F14);
        bar.setTextSize(18);
        bar.setGravity(17);
        barBox.addView(bar, new LinearLayout.LayoutParams(0, 56));
        overlay.addView(barBox, new LinearLayout.LayoutParams(barWidthPx, 56));

        root.addView(overlay, new FrameLayout.LayoutParams(-1, -1, 17));

        // links oben: drehender Mojave + Fortschritt des Karten-Downloads
        pill = new LinearLayout(this);
        pill.setOrientation(0);
        pill.setGravity(16);
        pill.setBackgroundColor(0xCC0B0F14);
        pill.setPadding(6, 2, 14, 2);
        mojave = new MojaveView(this);
        pill.addView(mojave, new LinearLayout.LayoutParams(46, 46));
        pillText = new TextView(this);
        pillText.setTextColor(0xFF4ADE80);
        pillText.setTextSize(15);
        pillText.setPadding(8, 0, 0, 0);
        pill.addView(pillText);
        FrameLayout.LayoutParams plp = new FrameLayout.LayoutParams(-2, 50, 51);
        plp.leftMargin = 330;
        plp.topMargin = 0;
        root.addView(pill, plp);

        setContentView(root);
        tiles = new TileStore(this);
        tiles.start();
        ui.postDelayed(new Task(this, Task.TICK, null, 0), 1000);
        hideBars();
        search();
    }

    void hideBars() {
        try { getWindow().getDecorView().setSystemUiVisibility(0x1706); } catch (Throwable t) { }
    }

    @Override
    protected void onResume() { super.onResume(); hideBars(); }

    @Override
    public void onWindowFocusChanged(boolean f) { super.onWindowFocusChanged(f); if (f) hideBars(); }

    @Override
    public void onBackPressed() {
        if (web.canGoBack()) web.goBack(); else super.onBackPressed();
    }

    void showOverlay(String text, int pct) { ui.post(new Task(this, Task.OVERLAY, text, pct)); }

    void applyOverlay(String text, int pct) {
        overlay.setVisibility(View.VISIBLE);
        status.setText(text);
        int p = Math.max(0, Math.min(100, pct));
        ViewGroup.LayoutParams lp = new LinearLayout.LayoutParams(Math.max(70, barWidthPx * p / 100), 56);
        bar.setLayoutParams(lp);
        bar.setText(p + " %");
    }

    void search() {
        if (searching) return;
        searching = true;
        new Thread(new Task(this, Task.WORKER, null, 0)).start();
    }

    void doSearch() {
            List<String> c = new ArrayList<String>();
            String last = prefs.getString("host", null);
            if (last != null) c.add(last);
            for (String h : FIXED) if (!c.contains(h)) c.add(h);
            for (int i = 1; i <= 15; i++) { String h = "172.20.10." + i; if (!c.contains(h)) c.add(h); }
            String found = null;
            for (int i = 0; i < c.size() && found == null; i++) {
                showOverlay("Suche Core Tracker … " + c.get(i), i * 100 / c.size());
                if (ok(c.get(i))) found = c.get(i);
            }
            searching = false;
            if (found != null) {
                String host = found;
                prefs.edit().putString("host", host).apply();
                piBase = "http://" + host + ":" + PORT;
                loadCarImage();
                showOverlay("Gefunden: " + host, 100);
                loaded = true;
                ui.post(new Task(this, Task.LOAD, "http://" + host + ":" + PORT + "/", 0));
            } else {
                showOverlay("Tracker nicht gefunden – ist der Pi im Hotspot? Neuer Versuch in 5 s", 100);
                ui.postDelayed(new Task(this, Task.SEARCH, null, 0), 5000);
            }
    }

    void loadCarImage() {
        if (mojave.img != null) return;
        byte[] d = TileStore.http(piBase + "/car.png", 3000);
        if (d != null && d.length > 0) mojave.img = android.graphics.BitmapFactory.decodeByteArray(d, 0, d.length);
    }

    void tick() {
        pillText.setText(tiles.finished ? "Karten komplett" : tiles.paused ? "Karten " + tiles.percent() + " % · wartet auf WLAN" : "Karten " + tiles.percent() + " %");
        ui.postDelayed(new Task(this, Task.TICK, null, 0), 1000);
    }

    /** Anpassungen der Tracker-Seite nur auf der Box: Maßstab nach rechts unten. */
    static final String CSS_JS = "(function(){var s=document.getElementById('ctbox');if(!s){s=document.createElement('style');s.id='ctbox';document.head.appendChild(s);}"
        + "s.textContent='#scale{position:fixed!important;right:110px!important;bottom:10px!important;left:auto!important;z-index:999;background:rgba(11,15,20,.65);border-radius:8px;min-width:90px}';})()";

    static boolean ok(String host) {
        try {
            HttpURLConnection con = (HttpURLConnection) new URL("http://" + host + ":" + PORT + "/").openConnection();
            con.setConnectTimeout(700);
            con.setReadTimeout(1500);
            int code = con.getResponseCode();
            con.disconnect();
            return code == 200;
        } catch (Throwable t) {
            return false;
        }
    }
}
