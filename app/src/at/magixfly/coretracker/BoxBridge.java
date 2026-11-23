package at.magixfly.coretracker;

import android.content.Context;
import android.content.SharedPreferences;
import android.os.SystemClock;
import android.util.Base64;
import android.util.Log;

import java.io.ByteArrayOutputStream;
import java.io.DataInputStream;
import java.io.InputStream;
import java.io.OutputStream;
import java.net.HttpURLConnection;
import java.net.Socket;
import java.net.URL;
import java.nio.ByteBuffer;
import java.nio.ByteOrder;
import java.util.ArrayList;
import java.util.Collections;
import java.util.regex.Matcher;
import java.util.regex.Pattern;

/**
 * V1.91: Fernwartung direkt auf der Box (ohne Pi), Wunsch Thorsten 23.11.
 * Befehle: GitHub Branch carlin, Ordner boxin/NNN_name.sh (Android-sh, läuft als root über lokales ADB).
 * Ergebnis: boxout/NNN_name.log (+ boxout/NNN_name.png bei Zeile „#screenshot“), Lebenszeichen boxout/status.txt (alle 10 min).
 * Schreiben braucht einen GitHub-Token (Pref ghToken, vom User auf der Fernsteuer-Seite :8090 eingetragen).
 * App-Update: apk/ver.txt höher als eigene Version → APK laden, „pm install“ als root (ohne Nachfrage).
 */
class BoxBridge {
    static final String REPO = "magixfly/-mojave-updates", BR = "carlin";
    static final String API = "https://api.github.com/repos/" + REPO + "/contents/";
    static final String RAW = "https://raw.githubusercontent.com/" + REPO + "/" + BR + "/";
    static volatile boolean running = false;
    static volatile String state = "";
    static long lastStatus = 0, lastUpd = 0;

    static void start(final Context c) {
        if (running) return;
        running = true;
        new Thread(new Runnable() { public void run() {
            SystemClock.sleep(30000);
            while (true) {
                SharedPreferences p = c.getSharedPreferences("ct", 0);
                try {
                    if (p.getBoolean("bbAuto", true)) {
                        poll(c);
                        long now = SystemClock.elapsedRealtime();
                        if (now - lastUpd > 5 * 60000L || lastUpd == 0) { lastUpd = now; update(c); }
                        if (tok(c).length() > 0 && (now - lastStatus > 10 * 60000L || lastStatus == 0)) { lastStatus = now; status(c); }
                    }
                } catch (Throwable t) { state = "Fehler: " + t.getMessage(); Log.d("CTBB", "loop: " + t); }
                SystemClock.sleep(tok(c).length() > 0 ? 30000 : 90000);   // ohne Token: GitHub erlaubt nur 60 Abfragen/h
            }
        } }).start();
    }

    static String tok(Context c) { return c.getSharedPreferences("ct", 0).getString("ghToken", "").trim(); }

    // ---------------------------------------------------------------- Befehle
    static void poll(Context c) throws Exception {
        String js = http("GET", API + "boxin?ref=" + BR, null, tok(c));
        if (js == null) { state = "keine Befehle (boxin fehlt?)"; return; }
        ArrayList<String> names = new ArrayList<String>();
        Matcher m = Pattern.compile("\"name\"\\s*:\\s*\"(\\d+_[^\"]*\\.sh)\"").matcher(js);
        while (m.find()) names.add(m.group(1));
        Collections.sort(names);
        SharedPreferences p = c.getSharedPreferences("ct", 0);
        int done = p.getInt("bbDone", -1);
        if (done < 0) {                                         // erster Start: alte Befehle nicht nachholen
            int mx = 0; for (String n : names) mx = Math.max(mx, num(n));
            p.edit().putInt("bbDone", mx).apply(); state = "bereit (ab Nr. " + (mx + 1) + ")"; return;
        }
        for (String n : names) {
            int k = num(n);
            if (k <= done) continue;
            p.edit().putInt("bbDone", k).apply();               // vorher merken: ein Befehl, der die App neu startet, läuft nicht doppelt
            String script = new String(get(RAW + "boxin/" + n), "UTF-8");
            state = "führe " + n + " aus";
            Log.d("CTBB", "starte " + n);
            long t0 = System.currentTimeMillis();
            String out = run(script, 600000);
            String base = n.substring(0, n.length() - 3);
            String log = "### " + base + "  –  " + new java.text.SimpleDateFormat("yyyy-MM-dd HH:mm:ss").format(new java.util.Date(t0))
                + "\n### Box direkt (App " + ver(c) + ", " + Autostart.ip() + ")\n\n" + out + "\n### Dauer " + (System.currentTimeMillis() - t0) / 1000 + " s\n";
            put(c, "boxout/" + base + ".log", log.getBytes("UTF-8"), "Box " + base);
            if (script.contains("#screenshot")) {
                String b = run("screencap -p | base64", 60000).replaceAll("\\s", "");
                if (b.length() > 100) put(c, "boxout/" + base + ".png", Base64.decode(b, Base64.DEFAULT), "Box " + base + " png");
            }
            state = "zuletzt " + n;
        }
    }

    static int num(String n) { try { return Integer.parseInt(n.substring(0, n.indexOf('_'))); } catch (Throwable t) { return 0; } }

    static void status(Context c) throws Exception {
        String wl = run("cmd wifi status | grep -m1 'connected to'; dumpsys tethering | grep -m1 -i 'TetheredState' ", 20000).trim();
        String s = "Stand: " + new java.text.SimpleDateFormat("yyyy-MM-dd HH:mm:ss").format(new java.util.Date())
            + "\nApp: " + ver(c) + "\nIP: " + Autostart.ip() + "\nWLAN: " + WlanOrder.state + "\n" + wl + "\nFernwartung: " + state + "\n";
        put(c, "boxout/status.txt", s.getBytes("UTF-8"), "Box status");
    }

    static String ver(Context c) { try { return c.getPackageManager().getPackageInfo(c.getPackageName(), 0).versionName; } catch (Throwable t) { return "?"; } }

    // ---------------------------------------------------------------- Update ohne Nachfrage (root)
    static void update(Context c) throws Exception {
        int cur = c.getPackageManager().getPackageInfo(c.getPackageName(), 0).versionCode;
        int neu = Integer.parseInt(new String(get(RAW + "apk/ver.txt"), "UTF-8").trim());
        if (neu <= cur) return;
        state = "Update " + cur + " → " + neu;
        Log.d("CTBB", state);
        byte[] apk = get(RAW + "apk/CoreTracker.apk");
        java.io.File f = new java.io.File(c.getExternalCacheDir() != null ? c.getExternalCacheDir() : c.getCacheDir(), "ct_update.apk");
        java.io.FileOutputStream fo = new java.io.FileOutputStream(f); fo.write(apk); fo.close();
        f.setReadable(true, false);
        // eigener Prozess (setsid), weil die Installation diese App beendet; danach App wieder starten
        run("cp " + f.getAbsolutePath() + " /data/local/tmp/ct_update.apk; setsid sh -c 'pm install -r /data/local/tmp/ct_update.apk; sleep 2; am start -n at.magixfly.coretracker/.MainActivity' </dev/null >/data/local/tmp/ct_update.log 2>&1 &", 20000);
    }

    // ---------------------------------------------------------------- GitHub
    static byte[] get(String u) throws Exception {
        HttpURLConnection h = (HttpURLConnection) new URL(u + (u.contains("?") ? "&" : "?") + "t=" + System.currentTimeMillis()).openConnection();
        h.setConnectTimeout(10000); h.setReadTimeout(60000);
        return readAll(h.getInputStream());
    }

    /** null bei 404 */
    static String http(String method, String u, String body, String token) throws Exception {
        HttpURLConnection h = (HttpURLConnection) new URL(u).openConnection();
        h.setConnectTimeout(10000); h.setReadTimeout(30000);
        h.setRequestMethod(method);
        h.setRequestProperty("Accept", "application/vnd.github+json");
        h.setRequestProperty("User-Agent", "CoreTracker-Box");
        if (token != null && token.length() > 0) h.setRequestProperty("Authorization", "Bearer " + token);
        if (body != null) { h.setDoOutput(true); h.setRequestProperty("Content-Type", "application/json"); OutputStream o = h.getOutputStream(); o.write(body.getBytes("UTF-8")); o.close(); }
        int rc = h.getResponseCode();
        if (rc == 404) return null;
        if (rc >= 300) { InputStream e = h.getErrorStream(); String m = e == null ? "" : new String(readAll(e), "UTF-8").replaceAll("\\s+", " "); throw new Exception("GitHub " + rc + " " + m.substring(0, Math.min(200, m.length()))); }
        return new String(readAll(h.getInputStream()), "UTF-8");
    }

    static void put(Context c, String path, byte[] data, String msg) throws Exception {
        String t = tok(c);
        if (t.length() == 0) { state = "kein GitHub-Token – Ergebnis nicht hochgeladen"; return; }
        String sha = null;
        String old = http("GET", API + path + "?ref=" + BR, null, t);
        if (old != null) { Matcher m = Pattern.compile("\"sha\"\\s*:\\s*\"([0-9a-f]+)\"").matcher(old); if (m.find()) sha = m.group(1); }
        String body = "{\"message\":\"" + msg.replace("\"", "'") + "\",\"branch\":\"" + BR + "\",\"content\":\"" + Base64.encodeToString(data, Base64.NO_WRAP) + "\"" + (sha != null ? ",\"sha\":\"" + sha + "\"" : "") + "}";
        for (int i = 0; i < 3; i++) {
            try { http("PUT", API + path, body, t); return; }
            catch (Exception e) { if (i == 2) throw e; SystemClock.sleep(3000); }
        }
    }

    static byte[] readAll(InputStream in) throws Exception {
        ByteArrayOutputStream b = new ByteArrayOutputStream(); byte[] buf = new byte[16384]; int r;
        while ((r = in.read(buf)) > 0) b.write(buf, 0, r);
        in.close(); return b.toByteArray();
    }

    // ---------------------------------------------------------------- Root-Shell über lokales ADB (eigene Kopie: lange Laufzeit, threadsicher)
    static final int CNXN = 0x4e584e43, OPEN = 0x4e45504f, OKAY = 0x59414b4f, WRTE = 0x45545257, CLSE = 0x45534c43;

    static String run(String script, int timeoutMs) {
        try {
            String b64 = Base64.encodeToString(script.getBytes("UTF-8"), Base64.NO_WRAP);
            String cmd = "echo " + b64 + " | base64 -d > /data/local/tmp/ctbb.sh; timeout " + (timeoutMs / 1000) + " sh /data/local/tmp/ctbb.sh 2>&1; echo; echo \"### Exit-Code: $?\"";
            return shell(cmd, timeoutMs + 15000);
        } catch (Throwable t) { return "Shell-Fehler: " + t; }
    }

    static synchronized String shell(String cmd, int timeoutMs) throws Exception {
        Socket s = new Socket("127.0.0.1", 5555);
        s.setSoTimeout(timeoutMs);
        try {
            OutputStream o = s.getOutputStream();
            DataInputStream in = new DataInputStream(s.getInputStream());
            send(o, CNXN, 0x01000001, 256 * 1024, "host::\0".getBytes("UTF-8"));
            byte[][] d = new byte[1][];
            int[] h = read(in, d);
            if (h[0] != CNXN) throw new Exception("kein CNXN");
            send(o, OPEN, 1, 0, ("shell:" + cmd + "\0").getBytes("UTF-8"));
            ByteArrayOutputStream out = new ByteArrayOutputStream();
            int remote = 0;
            while (true) {
                h = read(in, d);
                if (h[0] == OKAY) remote = h[1];
                else if (h[0] == WRTE) { out.write(d[0]); send(o, OKAY, 1, h[1], new byte[0]); if (out.size() > 6000000) break; }
                else if (h[0] == CLSE) { send(o, CLSE, 1, remote, new byte[0]); break; }
            }
            return out.toString("UTF-8");
        } finally { s.close(); }
    }

    static void send(OutputStream o, int cmd, int a0, int a1, byte[] data) throws Exception {
        ByteBuffer b = ByteBuffer.allocate(24 + data.length).order(ByteOrder.LITTLE_ENDIAN);
        int sum = 0; for (byte x : data) sum += (x & 0xff);
        b.putInt(cmd).putInt(a0).putInt(a1).putInt(data.length).putInt(sum).putInt(~cmd).put(data);
        o.write(b.array()); o.flush();
    }

    static int[] read(DataInputStream in, byte[][] d) throws Exception {
        byte[] hb = new byte[24]; in.readFully(hb);
        ByteBuffer b = ByteBuffer.wrap(hb).order(ByteOrder.LITTLE_ENDIAN);
        int cmd = b.getInt(), a0 = b.getInt(), a1 = b.getInt(), len = b.getInt();
        d[0] = new byte[len]; if (len > 0) in.readFully(d[0]);
        return new int[]{cmd, a0, a1};
    }
}
