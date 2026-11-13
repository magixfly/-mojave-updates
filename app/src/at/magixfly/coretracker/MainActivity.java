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
        plp.leftMargin = 300;
        plp.topMargin = 0;
        pill.setOnClickListener(new PillClick(this));
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
                showOverlay("Searching Core Tracker … " + c.get(i), i * 100 / c.size());
                if (ok(c.get(i))) found = c.get(i);
            }
            searching = false;
            if (found != null) {
                String host = found;
                prefs.edit().putString("host", host).apply();
                piBase = "http://" + host + ":" + PORT;
                loadCarImage();
                showOverlay("Found: " + host, 100);
                loaded = true;
                ui.post(new Task(this, Task.LOAD, "http://" + host + ":" + PORT + "/", 0));
            } else {
                showOverlay("Tracker not found – is the Pi in the hotspot? Retry in 5 s", 100);
                ui.postDelayed(new Task(this, Task.SEARCH, null, 0), 5000);
            }
    }

    void loadCarImage() {
        if (mojave.img != null) return;
        byte[] d = TileStore.http(piBase + "/car.png", 3000);
        if (d != null && d.length > 0) mojave.img = android.graphics.BitmapFactory.decodeByteArray(d, 0, d.length);
    }

    void tick() { updatePill(); ui.postDelayed(new Task(this, Task.TICK, null, 0), 1000); }

    void updatePill() {
        String mb = tiles.bytes.get() > 1024L * 1024 * 1024 ? String.format("%.1f GB", tiles.bytes.get() / 1073741824.0) : (tiles.bytes.get() / 1048576) + " MB";
        pillText.setText(tiles.finished ? "Maps complete" : tiles.full ? "Maps · storage full" : tiles.force ? "Maps " + mb + " · always loading (tap = auto)" : tiles.driving ? "Maps " + mb + " · paused while driving" : tiles.paused ? "Maps " + mb + " · waiting for Wi-Fi" : "Maps " + mb);
    }

    /** Anpassungen der Tracker-Seite nur auf der Box: Maßstab nach rechts unten. */
    /** Anpassungen der Tracker-Seite nur auf der Box: Maßstab rechts unten, Kompass, Beschriftung "heading". */
    static final String CSS_JS = "(function(){var s=document.getElementById('ctbox');if(!s){s=document.createElement('style');s.id='ctbox';document.head.appendChild(s);}if(document.getElementById('hdgComp')){s.textContent='';return;}s.textContent='#scale{position:fixed!important;right:110px!important;bottom:10px!important;left:auto!important;z-index:999;background:rgba(11,15,20,.65);border-radius:8px;min-width:90px}'+'#ctcomp{position:fixed;left:244px;bottom:14px;width:104px;height:104px;z-index:999;pointer-events:none}';if(document.getElementById('ctcomp')||document.getElementById('hdgComp'))return;var c=document.createElement('div');c.id='ctcomp';c.innerHTML='<svg viewBox=\"-60 -60 120 120\" width=\"104\" height=\"104\"><circle r=\"56\" fill=\"rgba(11,15,20,.72)\" stroke=\"#9ca3af\" stroke-width=\"2\"/>'+'<g id=\"ctrose\"><text y=\"-38\" text-anchor=\"middle\" fill=\"#ef4444\" font-size=\"16\" font-weight=\"800\">N</text><text x=\"42\" y=\"6\" text-anchor=\"middle\" fill=\"#e5e7eb\" font-size=\"13\" font-weight=\"700\">E</text>'+'<text y=\"49\" text-anchor=\"middle\" fill=\"#e5e7eb\" font-size=\"13\" font-weight=\"700\">S</text><text x=\"-42\" y=\"6\" text-anchor=\"middle\" fill=\"#e5e7eb\" font-size=\"13\" font-weight=\"700\">W</text></g>'+'<g id=\"ctarr\"><path d=\"M0,-30 L10,8 L0,2 L-10,8Z\" fill=\"#4ade80\"/></g><text id=\"cthdg\" y=\"30\" text-anchor=\"middle\" fill=\"#fff\" font-size=\"15\" font-weight=\"800\">–</text></svg>';document.body.appendChild(c);var a=document.getElementById('att');function upd(){if(!a)return;var t=a.textContent||'';var m=t.match(/(\\d+)\\u00b0\\s*$/); if(m&&t.indexOf('heading')<0){var h=+m[1];document.getElementById('ctarr').setAttribute('transform','rotate('+h+')');document.getElementById('cthdg').textContent=h+'\\u00b0';  var n=a.lastChild;if(n&&n.nodeType==3)n.nodeValue=n.nodeValue.replace(/\\u00b7\\s*(\\d+)\\u00b0\\s*$/,'\\u00b7 heading $1\\u00b0');}}if(a)new MutationObserver(upd).observe(a,{childList:true,characterData:true,subtree:true});upd();})()";

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
