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
    static final int MAP = 0, FULL = 1, PIP = 2;
    static final String[] FIXED = {"cosmostreamer.local", "172.20.10.10", "192.168.178.175"};

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
        tapCatcher.setOnClickListener(new View.OnClickListener() { public void onClick(View v) { setMode(FULL); } });
        tapCatcher.setVisibility(View.GONE);

        btn = new TextView(a);
        btn.setTextSize(19);
        btn.setTextColor(0xFF0B0F14);
        btn.setTypeface(null, 1);
        btn.setGravity(Gravity.CENTER);
        btn.setBackgroundColor(0xE64ADE80);
        btn.setPadding(26, 14, 26, 14);
        btn.setVisibility(View.GONE);
        btn.setOnClickListener(new View.OnClickListener() { public void onClick(View v) { setMode((mode + 1) % 3); } });
        FrameLayout.LayoutParams bl = new FrameLayout.LayoutParams(-2, -2, Gravity.RIGHT | Gravity.CENTER_VERTICAL);
        bl.rightMargin = 12;
        root.addView(btn, bl);

        new Thread(new Runnable() { public void run() { loop(); } }).start();
    }

    /** Hintergrund: CosmoStreamer suchen bzw. prüfen, ob er noch da ist (alle 10 s). */
    void loop() {
        while (true) {
            try {
                String b = base;
                if (b != null) {
                    if (isCosmo(b.substring(7))) misses = 0;
                    else if (++misses >= 3) { base = null; post(new Runnable() { public void run() { lost(); } }); }
                } else {
                    String h = find();
                    if (h != null) {
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
    static boolean isCosmo(String host) {
        try {
            HttpURLConnection con = (HttpURLConnection) new URL("http://" + host + "/").openConnection();
            con.setConnectTimeout(700);
            con.setReadTimeout(1500);
            if (con.getResponseCode() != 200) { con.disconnect(); return false; }
            InputStream in = con.getInputStream();
            byte[] buf = new byte[8192];
            int n = 0, r;
            while (n < buf.length && (r = in.read(buf, n, buf.length - n)) > 0) n += r;
            in.close();
            con.disconnect();
            return new String(buf, 0, n, "UTF-8").toLowerCase().contains("cosmostreamer");
        } catch (Throwable t) { return false; }
    }

    void post(Runnable r) { a.ui.post(r); }

    void found() { btn.setVisibility(View.VISIBLE); label(); }

    void lost() {
        setMode(MAP);
        btn.setVisibility(View.GONE);
    }

    void label() {
        btn.setText(mode == MAP ? "📷 FPV" : mode == FULL ? "▣ PiP" : "🗺 MAP");
    }

    void setMode(int m) {
        if (base == null) m = MAP;
        mode = m;
        label();
        if (m == MAP) {
            box.setVisibility(View.GONE);
            stopWeb();
            btn.bringToFront();
            return;
        }
        startWeb();
        FrameLayout.LayoutParams lp;
        if (m == FULL) {
            lp = new FrameLayout.LayoutParams(-1, -1);
            tapCatcher.setVisibility(View.GONE);
        } else {
            int w = Math.round(root.getWidth() * 0.34f), h = w * 9 / 16;
            lp = new FrameLayout.LayoutParams(w, h, Gravity.RIGHT | Gravity.TOP);
            lp.topMargin = 62;
            lp.rightMargin = 12;
            tapCatcher.setVisibility(View.VISIBLE);
        }
        box.setLayoutParams(lp);
        box.setVisibility(View.VISIBLE);
        box.bringToFront();
        btn.bringToFront();
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
            @Override public void onPermissionRequest(PermissionRequest r) { try { r.grant(r.getResources()); } catch (Throwable t) { } }
            @Override public boolean onConsoleMessage(android.webkit.ConsoleMessage m) { android.util.Log.d("CTFPV", m.message() + " @" + m.lineNumber()); return true; }
        });
        web.setWebViewClient(new WebViewClient() {
            @Override public void onPageFinished(WebView v, String url) { fix(); }
            @Override public void onReceivedError(WebView v, int code, String desc, String url) { info.setText("FPV: CosmoStreamer not reachable"); }
        });
        box.addView(web, 0, new FrameLayout.LayoutParams(-1, -1));
        box.addView(tapCatcher, new FrameLayout.LayoutParams(-1, -1));
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

    static final String JS = "(function(){"
        + "var ss=document.querySelectorAll('select');for(var i=0;i<ss.length;i++){var s=ss[i];for(var j=0;j<s.options.length;j++){var o=s.options[j];"
        + "if(/janus/i.test(o.text)&&s.selectedIndex!=j){s.selectedIndex=j;s.dispatchEvent(new Event('input',{bubbles:true}));s.dispatchEvent(new Event('change',{bubbles:true}));}}}"
        + "if(!document.getElementById('ctfpv')){var st=document.createElement('style');st.id='ctfpv';"
        + "st.textContent='html,body{background:#000!important;overflow:hidden!important}body *{visibility:hidden!important}"
        + "#remotevideov1{display:block!important;visibility:visible!important;position:fixed!important;left:0!important;top:0!important;width:100vw!important;height:100vh!important;"
        + "max-width:none!important;max-height:none!important;object-fit:contain!important;background:#000!important;z-index:2147483647!important;transform:none!important}';"
        + "document.head.appendChild(st);}"
        + "var vs=document.querySelectorAll('video,audio');for(var k=0;k<vs.length;k++){var v=vs[k];v.muted=true;v.volume=0;if(v.paused&&v.play)try{v.play();}catch(e){}}"
        + "var m=document.getElementById('remotevideov1');if(m){m.poster='data:image/gif;base64,R0lGODlhAQABAAAAACH5BAEAAAAALAAAAAABAAEAAAIBAAA=';"
        + "if(!window.ctdbg||Date.now()-window.ctdbg>6000){window.ctdbg=Date.now();console.log('FPVSTATE src='+!!m.srcObject+' rs='+m.readyState+' paused='+m.paused+' w='+m.videoWidth+' mode='+document.cookie+' janus='+(typeof Janus)+' rtc='+(typeof RTCPeerConnection));}}"
        + "return m&&m.videoWidth>0?1:0;})()";

    void fix() {
        if (web == null) return;
        web.evaluateJavascript(JS, new android.webkit.ValueCallback<String>() {
            public void onReceiveValue(String n) { info.setVisibility("0".equals(n) || n == null ? View.VISIBLE : View.GONE); }
        });
    }
}
