package at.magixfly.coretracker;

import android.content.Context;
import android.content.Intent;
import android.util.Log;

import java.io.InputStream;
import java.io.OutputStream;
import java.net.ServerSocket;
import java.net.Socket;

/**
 * V1.65: Bildschirm der Box im Browser: http://<Box-IP>:8090
 *  - Bild: MediaProjection (ProjService), JPEG ~5 Bilder/s, halbe Auflösung 960×360
 *  - Tippen ins Bild = Tippen auf der Box (Bedienungshilfe), Knöpfe Zurück / Home
 *  - Aufnahme startet erst, wenn jemand zuschaut; 60 s ohne Zuschauer = wieder aus (spart Strom/Hitze)
 */
public class ScreenShare {
    static final int PORT = 8090;
    static volatile byte[] jpg;
    static volatile long jpgT, lastView, reqT;
    static volatile String state = "idle";
    static boolean started;
    static Context app;

    static synchronized void server(Context c) {
        if (started) return;
        started = true;
        app = c.getApplicationContext();
        new Thread(new Runnable() { public void run() {
            try {
                ServerSocket ss = new ServerSocket(PORT);
                Log.d("CTSS", "Bildschirm-Server auf " + PORT);
                while (true) {
                    final Socket s = ss.accept();
                    new Thread(new Runnable() { public void run() { handle(s); } }).start();
                }
            } catch (Throwable t) { Log.d("CTSS", "server: " + t); started = false; }
        } }).start();
        new Thread(new Runnable() { public void run() {          // Aufnahme beenden, wenn keiner mehr zuschaut
            while (true) {
                try { Thread.sleep(10000); } catch (Throwable t) { }
                if (ProjService.running && System.currentTimeMillis() - lastView > 60000) ProjService.stopAll(app);
            }
        } }).start();
    }

    static boolean enabled() { return app.getSharedPreferences("ct", 0).getBoolean("share", true); }

    /** Erlaubnis zur Bildschirmaufnahme holen (Dialog bestätigt die Bedienungshilfe selbst). */
    static void request() {
        if (ProjService.running || System.currentTimeMillis() - reqT < 20000) return;
        reqT = System.currentTimeMillis();
        state = "asking";
        A11y.want("proj");
        try { app.startActivity(new Intent(app, ProjActivity.class).addFlags(Intent.FLAG_ACTIVITY_NEW_TASK | Intent.FLAG_ACTIVITY_NO_ANIMATION)); }
        catch (Throwable t) { Log.d("CTSS", "request: " + t); state = "error: " + t.getMessage(); }
    }

    static void handle(Socket s) {
        try {
            s.setSoTimeout(15000);
            InputStream in = s.getInputStream();
            StringBuilder sb = new StringBuilder(); int ch;
            while ((ch = in.read()) != -1) { sb.append((char) ch); if (sb.length() > 4 && sb.substring(sb.length() - 4).equals("\r\n\r\n")) break; if (sb.length() > 8000) break; }
            String first = sb.toString().split("\r\n")[0];
            String path = first.split(" ").length > 1 ? first.split(" ")[1] : "/";
            OutputStream o = s.getOutputStream();
            if (!enabled()) { text(o, "text/plain", "Bildschirm-Übertragung ist in „Box Autostart“ ausgeschaltet."); s.close(); return; }
            if (path.startsWith("/mjpeg")) { mjpeg(s, o); return; }
            if (path.startsWith("/shot.jpg")) {
                lastView = System.currentTimeMillis(); request();
                byte[] j = jpg;
                if (j == null) text(o, "text/plain", state);
                else { o.write(("HTTP/1.1 200 OK\r\nContent-Type: image/jpeg\r\nCache-Control: no-store\r\nContent-Length: " + j.length + "\r\nConnection: close\r\n\r\n").getBytes()); o.write(j); }
            } else if (path.startsWith("/tap")) {
                float x = num(path, "x"), y = num(path, "y");
                boolean ok = A11y.tap(x, y, path.contains("long=1") ? 700 : 60);
                text(o, "text/plain", ok ? "ok" : "no");
            } else if (path.startsWith("/swipe")) {
                boolean ok = A11y.swipe(num(path, "x"), num(path, "y"), num(path, "x2"), num(path, "y2"));
                text(o, "text/plain", ok ? "ok" : "no");
            } else if (path.startsWith("/key")) {
                text(o, "text/plain", A11y.key(path.contains("k=home") ? 2 : path.contains("k=recents") ? 3 : 1) ? "ok" : "no");
            } else if (path.startsWith("/state")) {
                text(o, "application/json", "{\"state\":\"" + state + "\",\"run\":" + ProjService.running + ",\"age\":" + (jpg == null ? -1 : System.currentTimeMillis() - jpgT) + "}");
            } else text(o, "text/html; charset=utf-8", PAGE);
            o.flush(); s.close();
        } catch (Throwable t) { try { s.close(); } catch (Throwable x) { } }
    }

    static float num(String p, String k) {
        java.util.regex.Matcher m = java.util.regex.Pattern.compile("[?&]" + k + "=([0-9.]+)").matcher(p);
        return m.find() ? Float.parseFloat(m.group(1)) : 0;
    }

    static void text(OutputStream o, String type, String t) throws java.io.IOException {
        byte[] b = t.getBytes("UTF-8");
        o.write(("HTTP/1.1 200 OK\r\nContent-Type: " + type + "\r\nCache-Control: no-store\r\nContent-Length: " + b.length + "\r\nConnection: close\r\n\r\n").getBytes());
        o.write(b);
    }

    static void mjpeg(Socket s, OutputStream o) throws Exception {
        o.write("HTTP/1.1 200 OK\r\nContent-Type: multipart/x-mixed-replace; boundary=ctframe\r\nCache-Control: no-store\r\nConnection: close\r\n\r\n".getBytes());
        long sent = 0;
        while (true) {
            lastView = System.currentTimeMillis();
            request();
            byte[] j = jpg; long t = jpgT;
            if (j != null && t != sent) {
                o.write(("--ctframe\r\nContent-Type: image/jpeg\r\nContent-Length: " + j.length + "\r\n\r\n").getBytes());
                o.write(j); o.write("\r\n".getBytes()); o.flush();
                sent = t;
            }
            Thread.sleep(150);
        }
    }

    static final String PAGE = "<!doctype html><html><head><meta name=viewport content='width=device-width,initial-scale=1'><title>Box-Bildschirm</title><style>"
        + "body{margin:0;background:#0b0f14;color:#e5e7eb;font:18px sans-serif}#bar{display:flex;gap:10px;align-items:center;padding:8px 10px}"
        + "button{background:#0b0f14;color:#4ade80;border:2px solid rgba(77,184,255,.6);border-radius:10px;font:700 18px sans-serif;padding:8px 18px;cursor:pointer}"
        + "#st{color:#9ca3af;flex:1}#w{position:relative}img{width:100%;display:block;cursor:crosshair;user-select:none;-webkit-user-drag:none}"
        + "#pb{height:22px;background:#18202a;border-radius:8px;margin:10px;position:relative;overflow:hidden;display:none}#pb i{position:absolute;left:0;top:0;bottom:0;background:#2563eb;width:0}#pb span{position:absolute;inset:0;text-align:center;font:700 14px/22px sans-serif}"
        + "</style></head><body><div id=bar><b style='color:#4ade80'>Box-Bildschirm</b><button onclick=\"k('back')\">◀ Zurück</button><button onclick=\"k('home')\">● Home</button><button onclick=\"k('recents')\">▢ Apps</button><span id=st>verbinde …</span></div>"
        + "<div id=pb><i></i><span></span></div><div id=w><img id=s draggable=false></div><script>"
        + "var s=document.getElementById('s'),st=document.getElementById('st'),pb=document.getElementById('pb'),t0=Date.now(),d=null;"
        + "s.src='/mjpeg';function k(x){fetch('/key?k='+x)}"
        + "function xy(e){var r=s.getBoundingClientRect();return[Math.round((e.clientX-r.left)/r.width*1920),Math.round((e.clientY-r.top)/r.height*720)]}"
        + "s.onpointerdown=function(e){d={p:xy(e),t:Date.now()};e.preventDefault()};"
        + "s.onpointerup=function(e){if(!d)return;var q=xy(e),p=d.p,dt=Date.now()-d.t;d=null;if(Math.abs(q[0]-p[0])+Math.abs(q[1]-p[1])>30)fetch('/swipe?x='+p[0]+'&y='+p[1]+'&x2='+q[0]+'&y2='+q[1]);else fetch('/tap?x='+p[0]+'&y='+p[1]+(dt>600?'&long=1':''))};"
        + "setInterval(function(){fetch('/state').then(r=>r.json()).then(j=>{var ok=j.age>=0&&j.age<3000;pb.style.display=ok?'none':'block';"
        + "var pc=Math.min(95,Math.round((Date.now()-t0)/150));pb.querySelector('i').style.width=pc+'%';pb.querySelector('span').textContent=(j.state=='asking'?'Erlaubnis zur Bildschirmaufnahme … ':'Starte Aufnahme … ')+pc+' %';"
        + "st.textContent=ok?'live':(j.state);if(ok)t0=Date.now();if(!ok&&j.age>5000){s.src='/mjpeg?'+Date.now()}}).catch(function(){st.textContent='Box nicht erreichbar'})},1000)"
        + "</script></body></html>";
}
