package at.magixfly.coretracker;

import android.graphics.Color;
import android.view.Gravity;
import android.view.View;
import android.webkit.PermissionRequest;
import android.webkit.WebChromeClient;
import android.webkit.WebSettings;
import android.webkit.WebView;
import android.webkit.WebViewClient;
import android.widget.FrameLayout;
import android.widget.TextView;

import java.io.InputStream;
import java.net.HttpURLConnection;
import java.net.URL;
import java.util.ArrayList;
import java.util.List;
import java.util.concurrent.atomic.AtomicReference;

/**
 * V1.26: optionales FPV-Bild vom CosmoStreamer-Pi (DJI Goggles 3 → WebRTC Janus).
 * Die Taste erscheint nur, wenn ein CosmoStreamer im Netz gefunden wird.
 * Antippen: Karte → FPV (Vollbild) → Bild-im-Bild → Karte.
 */
class Fpv {
    static final int MAP = 0, FULL = 1, PIP = 2, SPLIT = 3;
    static final String[] FIXED = {"cosmostreamer.local", "172.20.10.2", "172.20.10.3", "172.20.10.10", "192.168.178.175"};

    final MainActivity a;
    final FrameLayout root;
    TextView btn;
    TextView info;
    FrameLayout box;           // Rahmen für das FPV-Bild (Vollbild oder klein)
    WebView web;
    View tapCatcher;           // im Bild-im-Bild: Antippen = Vollbild
    volatile String base = null;
    int mode = MAP;
    long lastScan = 0;
    int misses = 0;
    volatile long ms = -1;

    Fpv(MainActivity a, FrameLayout root) {
        this.a = a;
        this.root = root;

        box = new FrameLayout(a);
        box.setBackgroundColor(Color.BLACK);
        box.setVisibility(View.GONE);
        root.addView(box, new FrameLayout.LayoutParams(-1, -1));

        info = new TextView(a);
        info.setTextColor(0xFF9CA3AF);
        info.setTextSize(18);
        info.setGravity(Gravity.CENTER);
        info.setText("FPV: connecting to CosmoStreamer …");
        box.addView(info, new FrameLayout.LayoutParams(-1, -1));

        tapCatcher = new View(a);
        tapCatcher.setOnTouchListener(new View.OnTouchListener() { public boolean onTouch(View v, android.view.MotionEvent e) { return pipTouch(e); } });
        tapCatcher.setVisibility(View.GONE);

        btn = new TextView(a);
        btn.setTextSize(18);
        btn.setTextColor(0xFF4ADE80);
        btn.setTypeface(null, 1);
        btn.setGravity(Gravity.CENTER);
        android.graphics.drawable.GradientDrawable bg = new android.graphics.drawable.GradientDrawable();
        bg.setColor(0xFF0B0F14);                     // V1.50: wie die Rahmen links (dunkel, blauer Rand, grüne Schrift)
        bg.setStroke(3, 0x994DB8FF);
        bg.setCornerRadius(14);
        btn.setBackground(bg);
        btn.setPadding(4, 0, 4, 0);
        btn.setVisibility(View.GONE);
        btn.setOnClickListener(new View.OnClickListener() { public void onClick(View v) { setMode(next(mode)); } });
        // V1.31: links unten unter dem GPS-Feld (verdeckt nichts mehr)
        // V1.34: links unten (gut erreichbar); die Lage-/GPS-Zeile ist dafür oben in der Kopfzeile
        FrameLayout.LayoutParams bl = new FrameLayout.LayoutParams(208, 62, Gravity.LEFT | Gravity.BOTTOM);
        bl.leftMargin = 10;
        bl.bottomMargin = 12;
        root.addView(btn, bl);

        new Thread(new Runnable() { public void run() { loop(); } }).start();
    }

    /** Hintergrund: CosmoStreamer suchen bzw. prüfen, ob er noch da ist (alle 10 s). */
    void loop() {
        while (true) {
            try {
                String b = base;
                if (b != null) {
                    long t0 = System.currentTimeMillis();
                    if (isCosmo(b.substring(7), true)) { misses = 0; ms = System.currentTimeMillis() - t0; }
                    else if (++misses >= 6) { base = null; post(new Runnable() { public void run() { lost(); } }); }
                } else {
                    String h = find();
                    if (h != null) {
                        try { String ip = java.net.InetAddress.getByName(h).getHostAddress(); if (isCosmo(ip, true)) h = ip; } catch (Throwable t) { }
                        a.prefs.edit().putString("cosmo", h).apply();
                        base = "http://" + h;
                        misses = 0;
                        post(new Runnable() { public void run() { found(); } });
                    }
                }
                Thread.sleep(10000);
            } catch (Throwable t) {
                try { Thread.sleep(10000); } catch (Throwable t2) { }
            }
        }
    }

    String find() {
        List<String> c = new ArrayList<String>();
        String last = a.prefs.getString("cosmo", null);
        if (last != null) c.add(last);
        for (String h : FIXED) if (!c.contains(h)) c.add(h);
        for (String h : c) if (isCosmo(h)) return h;
        // ganzes eigenes Netz höchstens alle 60 s absuchen
        if (System.currentTimeMillis() - lastScan < 60000) return null;
        lastScan = System.currentTimeMillis();
        try {
            List<String> hosts = new ArrayList<String>();
            for (java.net.NetworkInterface ni : java.util.Collections.list(java.net.NetworkInterface.getNetworkInterfaces())) {
                if (!ni.isUp() || ni.isLoopback()) continue;
                for (java.net.InetAddress ia : java.util.Collections.list(ni.getInetAddresses())) {
                    if (!(ia instanceof java.net.Inet4Address) || !ia.isSiteLocalAddress()) continue;
                    String ip = ia.getHostAddress(), pre = ip.substring(0, ip.lastIndexOf('.') + 1);
                    for (int i = 1; i < 255; i++) { String h = pre + i; if (!h.equals(ip) && !hosts.contains(h)) hosts.add(h); }
                }
            }
            if (hosts.isEmpty()) return null;
            java.util.concurrent.ExecutorService ex = java.util.concurrent.Executors.newFixedThreadPool(32);
            final AtomicReference<String> hit = new AtomicReference<String>();
            for (final String h : hosts) ex.execute(new Runnable() { public void run() { if (hit.get() == null && isCosmo(h)) hit.compareAndSet(null, h); } });
            ex.shutdown();
            ex.awaitTermination(20, java.util.concurrent.TimeUnit.SECONDS);
            ex.shutdownNow();
            return hit.get();
        } catch (Throwable t) { return null; }
    }

    /** Ist unter dieser Adresse (Port 80) die Seite des CosmoStreamers? */
    static boolean isCosmo(String host) { return isCosmo(host, false); }

    /** slow = bekannter CosmoStreamer: länger warten (antwortet unter Last bis ~1,5 s) */
    static boolean isCosmo(String host, boolean slow) {
        try {
            if (host.startsWith("corepi")) return false;   // V1.36: Tracker-Pi wird über seine Seite ausgeschlossen, nicht über die Adresse
            HttpURLConnection con = (HttpURLConnection) new URL("http://" + host + "/").openConnection();
            con.setConnectTimeout(slow ? 3000 : 700);
            con.setReadTimeout(slow ? 5000 : 1500);
            if (con.getResponseCode() != 200) { con.disconnect(); return false; }
            InputStream in = con.getInputStream();
            byte[] buf = new byte[8192];
            int n = 0, r;
            while (n < buf.length && (r = in.read(buf, n, buf.length - n)) > 0) n += r;
            in.close();
            con.disconnect();
            String t = new String(buf, 0, n, "UTF-8").toLowerCase();
            return t.contains("<title>cosmostreamer") && t.contains("video_player_option");   // V1.33: nur die echte CosmoStreamer-Seite
        } catch (Throwable t) { return false; }
    }

    void post(Runnable r) { a.ui.post(r); }

    void found() {
        btn.setVisibility(View.VISIBLE); label();
        int m = a.prefs.getInt("fpvMode", MAP);                 // V1.51: zuletzt gewählte Ansicht wiederherstellen
        if (m != MAP && mode == MAP) setMode(m);
    }

    void lost() {
        setMode(MAP);
        btn.setVisibility(View.GONE);
    }

    /** V1.32: Karte → Splitscreen → FPV Vollbild → Bild-im-Bild → Karte */
    static int next(int m) { return m == MAP ? SPLIT : m == SPLIT ? FULL : m == FULL ? PIP : MAP; }

    void label() {
        int n = next(mode);
        btn.setText(n == SPLIT ? "Split" : n == FULL ? "FPV" : n == PIP ? "PiP" : "MAP");   // V1.50: ohne Symbole
        // Breite wie die linke Spalte: normal 208 px, im Split ist die Spalte schmaler
        FrameLayout.LayoutParams bl = (FrameLayout.LayoutParams) btn.getLayoutParams();
        if (bl != null) {
            boolean sp = mode == SPLIT;
            bl.width = sp ? 125 : 208; bl.height = sp ? 56 : 62; bl.leftMargin = sp ? 6 : 10; bl.bottomMargin = sp ? 8 : 12;
            btn.setLayoutParams(bl);
        }
    }

    /** Karte (Tracker-WebView) volle Breite oder linke Hälfte. */
    void mapWidth(int w) {
        a.web.setLayoutParams(new FrameLayout.LayoutParams(w, -1, Gravity.LEFT | Gravity.TOP));
    }

    void setMode(int m) {
        if (base == null) m = MAP;
        else a.prefs.edit().putInt("fpvMode", m).apply();       // V1.51: merken
        mode = m;
        label();
        // V1.42: Split = FPV volle Höhe in 16:9 (1920×720 → 1280 breit), Karte links daneben
        // V1.45: Split-Video 10 % schmaler (Karte breiter), Bild wird auf volle Höhe gestreckt (object-fit fill)
        int vw = Math.min(Math.round(root.getWidth() * 0.75f), root.getHeight() * 16 / 9 * 9 / 10);
        mapWidth(m == SPLIT ? root.getWidth() - vw : -1);
        a.web.evaluateJavascript("document.documentElement.classList.toggle('ctsplit'," + (m == SPLIT) + ")", null);   // V1.48: Karten-Ansicht für Split
        if (m == MAP) {
            box.setVisibility(View.GONE);
            stopWeb();
            btn.bringToFront();
            return;
        }
        startWeb();
        web.evaluateJavascript("window.ctFill=" + (m == SPLIT) + ";", null);
        fill = (m == SPLIT);
        FrameLayout.LayoutParams lp;
        if (m == FULL) {
            lp = new FrameLayout.LayoutParams(-1, -1);
            tapCatcher.setVisibility(View.GONE);
        } else if (m == SPLIT) {
            lp = new FrameLayout.LayoutParams(vw, -1, Gravity.RIGHT | Gravity.TOP);
            tapCatcher.setVisibility(View.GONE);
        } else {
            lp = pipParams();
            tapCatcher.setVisibility(View.VISIBLE);
        }
        box.setLayoutParams(lp);
        box.setAlpha(m == PIP ? ALPHA[Math.max(0, Math.min(2, a.prefs.getInt("pipA", 0)))] : 1f);
        box.setVisibility(View.VISIBLE);
        box.bringToFront();
        btn.bringToFront();
    }

    // ---- V1.37: Bild-im-Bild verschieben (ziehen), Größe (doppeltippen), Vollbild (tippen) ----
    static final float[] SIZES = {0.25f, 0.34f, 0.45f};
    float dx, dy; int sx, sy; boolean drag; long lastUp, downT; Runnable single;
    static final float[] ALPHA = {1f, 0.8f, 0.6f};   // V1.46: lang drücken = Deckkraft 100/80/60 %

    FrameLayout.LayoutParams pipParams() {
        int W = root.getWidth(), H = root.getHeight();
        int si = Math.max(0, Math.min(2, a.prefs.getInt("pipS", 1)));
        int w = Math.round(W * SIZES[si]), h = w * 9 / 16;
        int x = a.prefs.getInt("pipX", W - w - 100), y = a.prefs.getInt("pipY", 68);
        x = Math.max(0, Math.min(W - w, x)); y = Math.max(0, Math.min(H - h, y));
        FrameLayout.LayoutParams lp = new FrameLayout.LayoutParams(w, h, Gravity.LEFT | Gravity.TOP);
        lp.leftMargin = x; lp.topMargin = y;
        return lp;
    }

    boolean pipTouch(android.view.MotionEvent e) {
        FrameLayout.LayoutParams lp = (FrameLayout.LayoutParams) box.getLayoutParams();
        switch (e.getActionMasked()) {
            case android.view.MotionEvent.ACTION_DOWN:
                dx = e.getRawX(); dy = e.getRawY(); sx = lp.leftMargin; sy = lp.topMargin; drag = false; downT = System.currentTimeMillis();
                return true;
            case android.view.MotionEvent.ACTION_MOVE:
                float mx = e.getRawX() - dx, my = e.getRawY() - dy;
                if (!drag && Math.abs(mx) + Math.abs(my) > 24) drag = true;
                if (drag) {
                    lp.leftMargin = Math.max(0, Math.min(root.getWidth() - lp.width, sx + Math.round(mx)));
                    lp.topMargin = Math.max(0, Math.min(root.getHeight() - lp.height, sy + Math.round(my)));
                    box.setLayoutParams(lp);
                }
                return true;
            case android.view.MotionEvent.ACTION_UP:
                if (drag) {
                    a.prefs.edit().putInt("pipX", lp.leftMargin).putInt("pipY", lp.topMargin).apply();
                    return true;
                }
                long now = System.currentTimeMillis();
                if (now - downT > 600) {                              // lang gedrückt: Deckkraft wechseln
                    int ai = (a.prefs.getInt("pipA", 0) + 1) % 3;
                    a.prefs.edit().putInt("pipA", ai).apply();
                    box.setAlpha(ALPHA[ai]);
                    return true;
                }
                if (now - lastUp < 350 && single != null) {          // Doppeltippen: Größe wechseln
                    a.ui.removeCallbacks(single); single = null; lastUp = 0;
                    a.prefs.edit().putInt("pipS", (a.prefs.getInt("pipS", 1) + 1) % 3)
                        .putInt("pipX", lp.leftMargin + lp.width).putInt("pipY", lp.topMargin).apply();
                    FrameLayout.LayoutParams n = pipParams();
                    n.leftMargin = Math.max(0, Math.min(root.getWidth() - n.width, lp.leftMargin + lp.width - n.width));  // rechte Kante bleibt
                    a.prefs.edit().putInt("pipX", n.leftMargin).apply();
                    box.setLayoutParams(n);
                    return true;
                }
                lastUp = now;
                single = new Runnable() { public void run() { single = null; if (mode == PIP) setMode(FULL); } };
                a.ui.postDelayed(single, 360);
                return true;
        }
        return true;
    }

    void startWeb() {
        if (web != null) return;
        web = new WebView(a);
        WebSettings s = web.getSettings();
        s.setJavaScriptEnabled(true);
        s.setDomStorageEnabled(true);
        s.setMediaPlaybackRequiresUserGesture(false);
        s.setUseWideViewPort(true);
        s.setLoadWithOverviewMode(true);
        web.setBackgroundColor(Color.BLACK);
        web.setWebChromeClient(new WebChromeClient() {
            @Override public boolean onJsAlert(WebView v, String url, String msg, android.webkit.JsResult r) { r.confirm(); android.util.Log.d("CTFPV", "alert: " + msg); return true; }
            @Override public boolean onJsConfirm(WebView v, String url, String msg, android.webkit.JsResult r) { r.cancel(); return true; }
            @Override public void onPermissionRequest(PermissionRequest r) { try { r.grant(r.getResources()); } catch (Throwable t) { } }
            @Override public boolean onConsoleMessage(android.webkit.ConsoleMessage m) { android.util.Log.d("CTFPV", m.message() + " @" + m.lineNumber()); return true; }
        });
        web.setWebViewClient(new WebViewClient() {
            @Override public void onPageFinished(WebView v, String url) { fix(); }
            @Override public void onReceivedError(WebView v, int code, String desc, String url) { info.setVisibility(View.VISIBLE); info.setText("CosmoStreamer \u2717 not reachable"); }
        });
        box.addView(web, 0, new FrameLayout.LayoutParams(-1, -1));
        box.addView(tapCatcher, new FrameLayout.LayoutParams(-1, -1));
        try { android.webkit.CookieManager.getInstance().setCookie(base, "video_player_mode=1; path=/"); } catch (Throwable t) { }
        web.loadUrl(base + "/");
        keepFixing();
    }

    void stopWeb() {
        if (web == null) return;
        WebView w = web;
        web = null;
        box.removeView(w);
        box.removeView(tapCatcher);
        try { w.loadUrl("about:blank"); w.destroy(); } catch (Throwable t) { }
    }

    /** Die Seite baut sich laufend auf – Janus-Player wählen und Video groß/stumm machen, alle 2 s prüfen. */
    void keepFixing() {
        a.ui.postDelayed(new Runnable() { public void run() { if (web != null) { fix(); keepFixing(); } } }, 2000);
    }

    /** Janus zuerst; kommt nach 12 s kein Bild, auf Jmuxer (Modus 0) umschalten. Nur das aktive Video groß zeigen, stumm. */
    static final String JS = "(function(){"
        + "window.alert=function(m){console.log('alert: '+m);};var ck='';try{ck=document.cookie;}catch(e){return 'none';}var mo=(ck.match(/video_player_mode=(\\d)/)||[])[1]||'1';var id=mo==='0'?'video_element':'remotevideov1';"
        + "var st=document.getElementById('ctfpv');if(!st){st=document.createElement('style');st.id='ctfpv';document.head.appendChild(st);}"
        + "var css='html,body{background:#000!important;overflow:hidden!important}body *{visibility:hidden!important}"
        + "#'+id+'{display:block!important;visibility:visible!important;position:fixed!important;left:0!important;top:0!important;width:100vw!important;height:100vh!important;"
        + "max-width:none!important;max-height:none!important;object-fit:'+(window.ctFill?'fill':'contain')+'!important;background:#000!important;z-index:2147483647!important;transform:none!important}';"
        + "if(st.textContent!=css)st.textContent=css;"
        + "var vs=document.querySelectorAll('video,audio');for(var k=0;k<vs.length;k++){var v=vs[k];v.muted=true;v.volume=0;"
        + "v.poster='data:image/gif;base64,R0lGODlhAQABAAAAACH5BAEAAAAALAAAAAABAAEAAAIBAAA=';if(v.paused&&v.play)try{v.play();}catch(e){}}"
        + "var m=document.getElementById(id);window.ctT0=window.ctT0||Date.now();var ok=m&&m.videoWidth>0;"
        + "if(!window.ctdbg||Date.now()-window.ctdbg>6000){window.ctdbg=Date.now();console.log('FPVSTATE id='+id+' rs='+(m&&m.readyState)+' w='+(m&&m.videoWidth));}"
        + "if(!ok&&Date.now()-window.ctT0>15000){var nm=mo==='0'?'1':'0';console.log('FPV: kein Bild -> Modus '+nm);document.cookie='video_player_mode='+nm+';path=/;max-age=31536000';location.reload();}"
        + "return ok?'ok':(mo==='0'?'Jmuxer':'Janus');})()";

    boolean fill = false;
    void fix() {
        if (web == null) return;
        web.evaluateJavascript("window.ctFill=" + fill + ";", null);
        a.web.evaluateJavascript("document.documentElement.classList.toggle('ctsplit'," + (mode == SPLIT) + ")", null);
        web.evaluateJavascript(JS, new android.webkit.ValueCallback<String>() {
            public void onReceiveValue(String n) {
                boolean ok = n != null && n.contains("ok");
                info.setVisibility(ok ? View.GONE : View.VISIBLE);
                if (!ok && base != null) {
                    String p = n == null ? "" : n.replace("\"", "");
                    info.setText("CosmoStreamer \u2713 " + base.substring(7) + (ms >= 0 ? " \u00b7 " + ms + " ms" : "")
                        + "\nwaiting for video \u2013 goggles on?" + (p.length() > 0 && !p.equals("null") ? "\n(trying " + p + ")" : ""));
                }
            }
        });
    }
}
