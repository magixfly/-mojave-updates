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
    Fpv fpv;
    volatile String piBase = null;
    volatile boolean searching = false;
    volatile boolean loaded = false;
    int barWidthPx = 600;
    int repN = 0;

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

        fpv = new Fpv(this, root);              // V1.26: optional FPV from the CosmoStreamer
        setContentView(root);
        AdbWifi.ensure(this);
        HotspotBoot.maybe(this);                 // V1.39: Box-Hotspot nach dem Start automatisch einschalten
        new Thread(new Runnable() { public void run() { netLoop(); } }).start();   // V1.43: WLAN/Hotspot der Box anzeigen
        A11y.enable(this);
        Updater.loop(this);
        if (getIntent() != null && getIntent().hasExtra("aptest")) {   // Test: Hotspot-Schalter per Bedienungshilfe
            A11y.want("ap"); startActivity(new Intent("android.settings.TETHER_SETTINGS").addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)); }                      // V1.52: Selbst-Update von GitHub
        if (getIntent() != null && getIntent().hasExtra("adbtest")) new Thread(new Runnable() { public void run() {
            try { android.util.Log.d("CTAP", "test: " + HotspotBoot.shell("id; getprop persist.adb.tcp.port; dumpsys tethering | grep -c TetheredState")); }
            catch (Throwable t) { android.util.Log.d("CTAP", "test-Fehler: " + t); } } }).start();
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
        if (fpv != null && fpv.mode != Fpv.MAP) { fpv.setMode(Fpv.MAP); return; }
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
            if (found == null) found = scanSubnet();     // V1.24: e.g. home Wi-Fi without corepi.local (mDNS)
            searching = false;
            if (found != null) {
                String host = found;
                prefs.edit().putString("host", host).apply();
                piBase = "http://" + host + ":" + PORT;
                showOverlay("Found: " + host, 100);
                loaded = true;
                ui.post(new Task(this, Task.LOAD, "http://" + host + ":" + PORT + "/", 0));
            } else {
                showOverlay("Tracker not found – is the Pi in the hotspot? Retry in 5 s", 100);
                ui.postDelayed(new Task(this, Task.SEARCH, null, 0), 5000);
            }
    }


    /** V1.24: look for the tracker in the own /24 network (all addresses at once, ~2 s). */
    String scanSubnet() {
        try {
            final List<String> hosts = new ArrayList<String>();
            for (java.net.NetworkInterface ni : java.util.Collections.list(java.net.NetworkInterface.getNetworkInterfaces())) {
                if (!ni.isUp() || ni.isLoopback()) continue;
                for (java.net.InetAddress ia : java.util.Collections.list(ni.getInetAddresses())) {
                    if (!(ia instanceof java.net.Inet4Address) || !ia.isSiteLocalAddress()) continue;
                    String ip = ia.getHostAddress(), pre = ip.substring(0, ip.lastIndexOf('.') + 1);
                    for (int i = 1; i < 255; i++) { String h = pre + i; if (!h.equals(ip) && !hosts.contains(h)) hosts.add(h); }
                }
            }
            if (hosts.isEmpty()) return null;
            showOverlay("Searching Core Tracker in the whole network (" + hosts.size() + " addresses) …", 95);
            java.util.concurrent.ExecutorService ex = java.util.concurrent.Executors.newFixedThreadPool(48);
            final java.util.concurrent.atomic.AtomicReference<String> hit = new java.util.concurrent.atomic.AtomicReference<String>();
            for (final String h : hosts) ex.execute(new Scan(h, hit));
            ex.shutdown();
            ex.awaitTermination(15, java.util.concurrent.TimeUnit.SECONDS);
            ex.shutdownNow();
            return hit.get();
        } catch (Throwable t) { return null; }
    }

    void tick() { updatePill(); ui.postDelayed(new Task(this, Task.TICK, null, 0), 1000); }

    static String size(long b) { return b >= 1073741824L ? String.format(java.util.Locale.US, "%.1f GB", b / 1073741824.0) : (b / 1048576) + " MB"; }

    volatile String netTxt = "";
    /** V1.43: WLAN der Box bzw. „Hotspot“ in der Kopfzeile (über die lokale Root-Shell, alle 15 s). */
    void netLoop() {
        while (true) {
            try {
                if (HotspotBoot.apOn(this)) { netTxt = "Box: Hotspot"; throw new RuntimeException("ap"); }
                String r = HotspotBoot.shell("dumpsys tethering | grep -c TetheredState; cmd wifi status | grep -m1 'connected to'; dumpsys wifi | grep -m1 mWifiInfo | grep -o 'RSSI: -[0-9]*'; ip neigh 2>/dev/null | grep -v FAILED | grep -c -E 'ap|wlan|swlan'");
                String[] l = r.split("\n");
                int teth = 0; try { teth = Integer.parseInt(l[0].trim()); } catch (Throwable t) { }
                String t;
                if (teth > 0) t = "Box: Hotspot";
                else {
                    java.util.regex.Matcher m = java.util.regex.Pattern.compile("connected to \"([^\"]*)\"").matcher(r);
                    java.util.regex.Matcher q = java.util.regex.Pattern.compile("RSSI: (-\\d+)").matcher(r);
                    t = m.find() ? "Box: " + m.group(1) + (q.find() ? " " + q.group(1) + " dBm" : "") : "Box: no Wi-Fi";
                }
                netTxt = t;
            } catch (Throwable e) { if (!"ap".equals(e.getMessage())) netTxt = wifiTxt(); }
            final String js = "(function(){var e=document.getElementById('ctNet');if(!e){e=document.createElement('span');e.id='ctNet';e.title='Box Wi-Fi';var a=document.getElementById('att');if(a&&a.parentNode)a.parentNode.insertBefore(e,a.nextSibling);else document.body.appendChild(e);}e.textContent='" + netTxt.replace("'", "") + "';})()";
            ui.post(new Runnable() { public void run() { if (loaded) web.evaluateJavascript(js, null); } });
            try { Thread.sleep(15000); } catch (Throwable e) { }
        }
    }

    String wifiTxt() {
        try {
            android.net.wifi.WifiManager wm = (android.net.wifi.WifiManager) getApplicationContext().getSystemService(WIFI_SERVICE);
            android.net.wifi.WifiInfo wi = wm.getConnectionInfo();
            if (wi == null || wi.getNetworkId() == -1) return "Box: SIM";
            String ss = wi.getSSID(); if (ss == null || ss.contains("unknown")) ss = "Wi-Fi"; ss = ss.replace("\"", "");
            return "Box: " + ss + " " + wi.getRssi() + " dBm";
        } catch (Throwable t) { return "Box: ?"; }
    }

    void updatePill() {
        if (!loaded) return;
        long b1 = tiles.bytes.get(), b2 = tiles.estimate();
        String mb = (b1 >= 1073741824L && b2 >= 1073741824L) ? String.format(java.util.Locale.US, "%.1f/%.1f GB", b1 / 1073741824.0, b2 / 1073741824.0) : size(b1) + "/" + size(b2);   // V1.23: shorter
        String net = tiles.netType();
        boolean on = tiles.loadingNow();
        String txt = tiles.finished ? "Maps \u2713"                      // V1.38: kurze Texte (Tippen = Stopp/Start bleibt)
                : tiles.full ? "Maps " + mb + " \u00b7 full"
                : tiles.stopped ? "Maps " + mb + " \u00b7 stopped"
                : tiles.driving ? "Maps " + mb + " \u00b7 driving"
                : net == null ? "Maps " + mb + " \u00b7 offline"
                : on ? "Maps " + mb + " \u00b7 loading"
                : "Maps " + mb + " \u00b7 starting";
        if (piBase != null && (++repN % 3) == 0)                 // V1.25: tell the tracker on the Pi (shown on PC / phone / 7" display)
            new Thread(new Report(this, piBase, txt, on, b1 / 1073741824.0, b2 / 1073741824.0, net, tiles.stopped)).start();
        web.evaluateJavascript("(function(){var e=document.getElementById('ctMapsT');if(e)e.textContent='" + txt + "';var m=document.getElementById('ctMaps');if(m){m.dataset.dl='" + (on ? 1 : 0) + "';var i=m.querySelector('img');if(i)i.style.animationPlayState='" + (on ? "running" : "paused") + "';}})()", null);
    }

    /** Anpassungen der Tracker-Seite nur auf der Box: Karten-Anzeige mit drehendem Mojave in der Statusleiste, Schrift gleich groß. */
    static final String CSS_JS = "(function(){var s=document.getElementById('ctbox');if(!s){s=document.createElement('style');s.id='ctbox';document.head.appendChild(s);}var css='#ver{position:absolute;left:230px;top:0;height:60px;display:flex!important;align-items:center;font-size:19px!important;font-weight:400}'+'#sys,#esp,#wifi,#ctMaps,#bInfo.on,#cl{display:inline-flex!important;align-items:center;justify-content:center;gap:8px;font-size:19px!important;font-weight:700;border:2px solid rgba(77,184,255,.6);border-radius:10px;padding:0 12px;white-space:nowrap;font-variant-numeric:tabular-nums;height:46px;box-sizing:border-box}'+'#cl{border-color:#d97757}#sys *,#esp *,#wifi *{font-size:19px!important}#sys i{width:28px!important;height:9px!important}'+'html.ctsplit #top{display:none!important}html.ctsplit #map{top:0!important;height:100%!important}html.ctsplit #side,html.ctsplit #warn{top:0!important}html.ctsplit #tGps,html.ctsplit #side .s,html.ctsplit #side .row.s,html.ctsplit #bAz,html.ctsplit #bFind,html.ctsplit #vAlt{display:none!important}html.ctsplit body #side .t .v,html.ctsplit body #side .t .v span{font-size:64px!important;line-height:1.05!important}html.ctsplit body #side .t .v small{font-size:24px!important}html.ctsplit #side .l{font-size:19px!important;font-weight:800!important}html.ctsplit #side .t{padding:12px 12px 14px!important}'+'#top{height:60px!important}#map{top:60px!important;height:calc(100% - 60px)!important}#side,#warn,#rideSide,#side2{top:60px!important}'+'#top .sp{flex:0 0 420px!important}#sys,#esp,#wifi{flex:1 1 0;min-width:0;overflow:hidden}#top{gap:10px!important}'+'#ctMaps{position:absolute;left:322px;top:7px;color:#4ade80;cursor:pointer;min-width:0;max-width:330px;justify-content:center!important;padding-left:48px!important}#ctMaps img{position:absolute;left:12px;top:4px}#cl{margin-right:4px}#sys{flex:1.6 1 0!important;padding:0 14px!important}#sys>*{flex:none}#bInfo.on{position:absolute;left:322px;top:7px;border-color:#fbbf24;min-width:330px}'+'#map{transform:perspective(1400px) rotateX(24deg) scale(1.36);transform-origin:50% 88%}'+'#att *{font-size:19px!important}#att:empty{visibility:hidden!important}#ctNet{position:static;flex:none;margin:0;align-self:center;width:182px;height:46px;box-sizing:border-box;display:flex;align-items:center;justify-content:center;border:2px solid rgba(77,184,255,.6);border-radius:10px;background:#0b0f14;font-size:19px!important;font-weight:700;color:#4ade80;white-space:nowrap;overflow:hidden}'+'#att{position:static!important;flex:none!important;margin:0!important;align-self:center!important;transform:none!important;width:182px!important;height:46px!important;box-sizing:border-box!important;display:flex!important;align-items:center!important;justify-content:center!important;border:2px solid rgba(77,184,255,.6)!important;border-radius:10px!important;padding:0 8px!important;background:#0b0f14!important;font-size:19px!important;font-weight:700!important;line-height:1!important;white-space:nowrap!important;overflow:hidden!important;text-overflow:ellipsis!important;z-index:5}'+'#ctMaps img{height:28px;width:28px;object-fit:contain;animation:ctspin 3s linear infinite}@keyframes ctspin{to{transform:rotate(360deg)}}#top:has(#bInfo.on) #ctMaps{display:none!important}';var own=!!document.getElementById('hdgComp');if(!own)css+='#scale{position:fixed!important;right:110px!important;bottom:10px!important;left:auto!important;z-index:999;background:rgba(11,15,20,.65);border-radius:8px;min-width:90px;color:#f3f4f6}#scale div{border-color:#f3f4f6!important}'+'#ctcomp{position:fixed;left:244px;bottom:14px;width:104px;height:104px;z-index:999;pointer-events:none}';s.textContent=css;var tp=document.getElementById('top'),at=document.getElementById('att');if(tp&&at&&at.parentNode!==tp){var sp=tp.querySelector('.sp');tp.insertBefore(at,sp?sp.nextSibling:null);}if(!document.getElementById('ctMaps')){var v=document.getElementById('ver');var m=document.createElement('span');m.id='ctMaps'; m.innerHTML='<img src=\"car.png\"><span id=\"ctMapsT\">Maps</span>';m.onclick=function(){fetch('/__ctbox/toggle')}; if(v&&v.parentNode)v.parentNode.insertBefore(m,v.nextSibling);else document.body.appendChild(m);}if(!window.ctTouch){window.ctTouch=1;document.addEventListener('touchstart',function(e){var t=document.getElementById('ctMapsT');window.ctTn=e.touches.length;if(t&&e.touches.length>1){t.dataset.f=Date.now();t.textContent='Touch: '+e.touches.length+' fingers';}},{capture:true,passive:true});}if(own||document.getElementById('ctcomp'))return;var c=document.createElement('div');c.id='ctcomp';c.innerHTML='<svg viewBox=\"-60 -60 120 120\" width=\"104\" height=\"104\"><circle r=\"56\" fill=\"rgba(11,15,20,.72)\" stroke=\"#9ca3af\" stroke-width=\"2\"/>'+'<text y=\"-38\" text-anchor=\"middle\" fill=\"#ef4444\" font-size=\"16\" font-weight=\"800\">N</text><text x=\"42\" y=\"6\" text-anchor=\"middle\" fill=\"#e5e7eb\" font-size=\"13\" font-weight=\"700\">E</text>'+'<text y=\"49\" text-anchor=\"middle\" fill=\"#e5e7eb\" font-size=\"13\" font-weight=\"700\">S</text><text x=\"-42\" y=\"6\" text-anchor=\"middle\" fill=\"#e5e7eb\" font-size=\"13\" font-weight=\"700\">W</text>'+'<g id=\"ctarr\"><path d=\"M0,-30 L10,8 L0,2 L-10,8Z\" fill=\"#4ade80\"/></g><text id=\"cthdg\" y=\"30\" text-anchor=\"middle\" fill=\"#fff\" font-size=\"15\" font-weight=\"800\">–</text></svg>';document.body.appendChild(c);var a=document.getElementById('att');function upd(){if(!a)return;var hd=a.dataset.hdg;var t=a.textContent||'';var m=hd?[0,hd]:t.match(/(\\d+)\\u00b0\\s*$/); if(m&&(hd||t.indexOf('heading')<0)){var h=+m[1];document.getElementById('ctarr').setAttribute('transform','rotate('+h+')');document.getElementById('cthdg').textContent=h+'\\u00b0';  var n=a.lastChild;if(n&&n.nodeType==3)n.nodeValue=n.nodeValue.replace(/\\u00b7\\s*(\\d+)\\u00b0\\s*$/,'\\u00b7 heading $1\\u00b0');}}if(a)new MutationObserver(upd).observe(a,{childList:true,characterData:true,subtree:true,attributes:true});upd();})()";

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
