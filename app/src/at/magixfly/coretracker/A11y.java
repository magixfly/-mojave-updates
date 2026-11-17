package at.magixfly.coretracker;

import android.accessibilityservice.AccessibilityService;
import android.content.ComponentName;
import android.content.Context;
import android.content.Intent;
import android.provider.Settings;
import android.util.Log;
import android.view.accessibility.AccessibilityEvent;
import android.view.accessibility.AccessibilityNodeInfo;

import java.util.List;

/**
 * V1.52: Bedienungshilfe der App (ohne Root/ADB):
 *  - "ap": in den Hotspot-Einstellungen den Schalter „WLAN-Hotspot“ einschalten, dann zurück zur Karte
 *  - "inst": beim eigenen App-Update „Installieren/Aktualisieren“ bestätigen
 */
public class A11y extends AccessibilityService {
    static volatile String task = null;
    static volatile long taskT = 0;

    static void want(String t) { task = t; taskT = System.currentTimeMillis(); }

    /** Bedienungshilfe selbst einschalten (geht dank WRITE_SECURE_SETTINGS). */
    static void enable(Context c) {
        try {
            String me = new ComponentName(c, A11y.class).flattenToString();
            String cur = Settings.Secure.getString(c.getContentResolver(), Settings.Secure.ENABLED_ACCESSIBILITY_SERVICES);
            if (cur == null) cur = "";
            if (!cur.contains(me)) Settings.Secure.putString(c.getContentResolver(), Settings.Secure.ENABLED_ACCESSIBILITY_SERVICES, cur.isEmpty() ? me : cur + ":" + me);
            Settings.Secure.putString(c.getContentResolver(), Settings.Secure.ACCESSIBILITY_ENABLED, "1");
        } catch (Throwable t) { Log.d("CTAP", "a11y enable: " + t); }
    }

    @Override public void onAccessibilityEvent(AccessibilityEvent e) {
        String t = task;
        if (t == null) return;
        if (System.currentTimeMillis() - taskT > 60000) { task = null; return; }
        AccessibilityNodeInfo root = getRootInActiveWindow();
        if (root == null) return;
        try {
            if (t.equals("ap")) doAp(root);
            else if (t.equals("inst")) doInst(root);
            else if (t.equals("band")) doBand(root);
            else if (t.equals("proj")) doProj(root);
        } catch (Throwable x) { Log.d("CTAP", "a11y: " + x); }
    }

    void doAp(AccessibilityNodeInfo root) {
        List<AccessibilityNodeInfo> hs = root.findAccessibilityNodeInfosByText("WLAN-Hotspot");
        if (hs.isEmpty()) hs = root.findAccessibilityNodeInfosByText("Wi-Fi hotspot");
        if (hs.isEmpty()) return;
        android.graphics.Rect hr = new android.graphics.Rect(); hs.get(0).getBoundsInScreen(hr);
        java.util.ArrayList<AccessibilityNodeInfo> sws = new java.util.ArrayList<AccessibilityNodeInfo>();
        collect(root, sws);
        AccessibilityNodeInfo best = null; int bd = 99999;
        for (AccessibilityNodeInfo n : sws) {
            android.graphics.Rect r = new android.graphics.Rect(); n.getBoundsInScreen(r);
            Log.d("CTAP", "Schalter " + n.getClassName() + " checked=" + n.isChecked() + " " + r.toShortString());
            int d = Math.abs(r.centerY() - hr.centerY());
            if (d < bd) { bd = d; best = n; }
        }
        Log.d("CTAP", "Hotspot-Text " + hr.toShortString() + ", Schalter: " + sws.size());
        if (best == null || bd > 200) return;               // Seite noch nicht fertig aufgebaut
        if (!best.isChecked()) {
            AccessibilityNodeInfo c = best;
            while (c != null && !c.isClickable()) c = c.getParent();
            boolean ok = c != null && c.performAction(AccessibilityNodeInfo.ACTION_CLICK);
            Log.d("CTAP", "Hotspot-Schalter angetippt: " + ok);
        } else Log.d("CTAP", "Hotspot war schon an");
        task = null;
        final boolean band = getSharedPreferences("ct", 0).getBoolean("ap5", true) && (!bandDone || Autostart.forceBand);
        new android.os.Handler(getMainLooper()).postDelayed(new Runnable() { public void run() {
            if (band) startBand(A11y.this, true);           // V1.57/59: gleich weiter zum 5-GHz-Band
            else goBack();
        } }, band ? 6000 : 2500);
    }

    // ---- V1.57: Hotspot-Band auf 5 GHz festlegen (Einstellungen → WLAN-Hotspot → (Erweitert) → AP-Band → 5 GHz) ----
    static volatile boolean bandDone = false;
    static long lastAct = 0;
    static int stage = 0;

    static void startBand(Context c) { startBand(c, false); }
    static void startBand(Context c, boolean force) {
        if (bandDone && !force || !c.getSharedPreferences("ct", 0).getBoolean("ap5", true)) return;
        bandDone = true; stage = 0; Autostart.forceBand = false;                          // nur einmal pro Start
        want("band");
        try { c.startActivity(new Intent("android.settings.TETHER_SETTINGS").addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)); } catch (Throwable t) { Log.d("CTAP", "band: " + t); }
        Log.d("CTAP", "Band: Hotspot-Seite geöffnet");
    }

    void texts(AccessibilityNodeInfo n, java.util.List<AccessibilityNodeInfo> out) {
        if (n == null) return;
        if (n.getText() != null && n.getText().length() > 0) out.add(n);
        for (int i = 0; i < n.getChildCount(); i++) texts(n.getChild(i), out);
    }
    static String tx(AccessibilityNodeInfo n) { return n.getText() == null ? "" : n.getText().toString(); }
    static boolean is5(String t) { String l = t.toLowerCase(); return l.contains("5") && l.contains("ghz") && !l.contains("2,4") && !l.contains("2.4") && !l.contains("6 ghz"); }
    boolean click(AccessibilityNodeInfo n, String why) {
        AccessibilityNodeInfo c = n;
        while (c != null && !c.isClickable()) c = c.getParent();
        boolean ok = c != null && c.performAction(AccessibilityNodeInfo.ACTION_CLICK);
        Log.d("CTAP", "Band: " + why + " → " + ok);
        if (ok) lastAct = System.currentTimeMillis();
        return ok;
    }
    /** V1.59: zurück zur Karte, wenn sie offen war (oder „Karte beim Start öffnen“ an ist), sonst zum Startbildschirm */
    void goBack() {
        Class<?> back = Autostart.backTo;
        Autostart.backTo = null;
        if (back != null) startActivity(new Intent(this, back).addFlags(Intent.FLAG_ACTIVITY_NEW_TASK | Intent.FLAG_ACTIVITY_REORDER_TO_FRONT));
        else if (MainActivity.alive || getSharedPreferences("ct", 0).getBoolean("mapAuto", false))
            startActivity(new Intent(this, MainActivity.class).addFlags(Intent.FLAG_ACTIVITY_NEW_TASK | Intent.FLAG_ACTIVITY_REORDER_TO_FRONT));
        else performGlobalAction(GLOBAL_ACTION_HOME);
    }

    void bandFinish(String why) {
        Log.d("CTAP", "Band fertig: " + why);
        task = null;
        new android.os.Handler(getMainLooper()).postDelayed(new Runnable() { public void run() {
            goBack();
        } }, 2500);
    }

    void doBand(AccessibilityNodeInfo root) {
        if (System.currentTimeMillis() - lastAct < 1500) return;   // Seite nach einem Tipp erst aufbauen lassen
        java.util.ArrayList<AccessibilityNodeInfo> all = new java.util.ArrayList<AccessibilityNodeInfo>();
        texts(root, all);
        // 1) Auswahl-Dialog offen: 5-GHz-Eintrag wählen (exakte Variante vor „bevorzugt“)
        if (stage >= 2) {
            AccessibilityNodeInfo pick = null;
            for (AccessibilityNodeInfo n : all) { String t = tx(n); if (is5(t) && t.length() < 30) { if (pick == null || !t.toLowerCase().contains("bevorzug") && !t.toLowerCase().contains("prefer")) pick = n; } }
            if (pick != null && all.size() < 12) { click(pick, "gewählt " + tx(pick)); stage = 3; bandFinish("5 GHz gesetzt"); return; }
        }
        // 2) Eintrag „AP-Band“ / „Band“ auf der Hotspot-Seite
        for (AccessibilityNodeInfo n : all) {
            String t = tx(n), l = t.toLowerCase();
            if ((l.contains("ap-band") || l.equals("band") || l.contains("frequenzband") || l.contains("ap band") || l.endsWith("-band") && !l.contains("ghz")) && !l.contains("ghz")) {
                AccessibilityNodeInfo row = n.getParent();
                java.util.ArrayList<AccessibilityNodeInfo> sub = new java.util.ArrayList<AccessibilityNodeInfo>();
                texts(row != null ? row : n, sub);
                for (AccessibilityNodeInfo x : sub) if (x != n && is5(tx(x))) { bandFinish("schon 5 GHz (" + tx(x) + ")"); return; }
                if (click(n, "AP-Band öffnen")) stage = 2;
                return;
            }
        }
        // 3) „Erweitert“ aufklappen
        for (AccessibilityNodeInfo n : all) { String l = tx(n).toLowerCase(); if (l.equals("erweitert") || l.equals("advanced") || l.startsWith("erweitert")) { click(n, "Erweitert"); return; } }
        // 4) Tethering-Seite: Unterseite „WLAN-Hotspot“ öffnen
        if (stage == 0) for (AccessibilityNodeInfo n : all) { String l = tx(n).toLowerCase(); if (l.equals("wlan-hotspot") || l.equals("wi-fi hotspot") || l.equals("mobiler hotspot")) { if (click(n, "Hotspot-Seite")) stage = 1; return; } }
    }

    void collect(AccessibilityNodeInfo n, java.util.List<AccessibilityNodeInfo> out) {
        if (n == null) return;
        if (n.isCheckable()) out.add(n);
        for (int i = 0; i < n.getChildCount(); i++) collect(n.getChild(i), out);
    }

    void doInst(AccessibilityNodeInfo root) {
        String[] words = {"Installieren", "Aktualisieren", "Install", "Update"};
        for (String w : words) {
            List<AccessibilityNodeInfo> l = root.findAccessibilityNodeInfosByText(w);
            for (AccessibilityNodeInfo n : l) {
                CharSequence cn = n.getClassName();
                if (cn != null && cn.toString().endsWith("Button") && n.isEnabled()) {
                    n.performAction(AccessibilityNodeInfo.ACTION_CLICK);
                    Log.d("CTAP", "Update bestätigt: " + w);
                    task = null;
                    return;
                }
            }
        }
    }

    /** V1.58: Die Bedienungshilfe startet das System beim Hochfahren von selbst – unabhängig davon, ob die App geöffnet wird.
     *  Darum hier Hotspot einschalten + 5 GHz festlegen (läuft nur einmal pro Start). */
    // ---- V1.65: Bildschirm-Übertragung ----
    static A11y me;

    /** Dialog „Bildschirm teilen / Jetzt starten“ bestätigen */
    void doProj(AccessibilityNodeInfo root) {
        String[] words = {"Jetzt starten", "Start now", "Bildschirm teilen", "Share screen", "Starten", "Start", "Teilen", "Weiter", "Next"};
        for (String w : words) {
            for (AccessibilityNodeInfo n : root.findAccessibilityNodeInfosByText(w)) {
                CharSequence cn = n.getClassName(); String tx = n.getText() == null ? "" : n.getText().toString();
                if (cn != null && cn.toString().endsWith("Button") && n.isEnabled() && tx.equalsIgnoreCase(w)) {
                    n.performAction(AccessibilityNodeInfo.ACTION_CLICK);
                    Log.d("CTSS", "Aufnahme-Dialog bestätigt: " + w);
                    if (!w.equals("Weiter") && !w.equals("Next")) task = null;
                    return;
                }
            }
        }
    }

    static boolean key(int a) { A11y s = me; return s != null && s.performGlobalAction(a); }   // 1 = Zurück, 2 = Home, 3 = Apps
    static boolean tap(float x, float y, long ms) { return gesture(x, y, x, y, ms); }
    static boolean swipe(float x, float y, float x2, float y2) { return gesture(x, y, x2, y2, 350); }

    /** Tippen/Wischen über dispatchGesture (API 24, per Reflection – android-23-SDK kennt es nicht) */
    static boolean gesture(float x, float y, float x2, float y2, long ms) {
        A11y s = me;
        if (s == null) return false;
        try {
            android.graphics.Path p = new android.graphics.Path();
            p.moveTo(x, y); if (x2 != x || y2 != y) p.lineTo(x2, y2);
            Class<?> sd = Class.forName("android.accessibilityservice.GestureDescription$StrokeDescription");
            Object stroke = sd.getConstructor(android.graphics.Path.class, long.class, long.class).newInstance(p, 0L, ms);
            Class<?> bc = Class.forName("android.accessibilityservice.GestureDescription$Builder");
            Object b = bc.newInstance();
            bc.getMethod("addStroke", sd).invoke(b, stroke);
            Object g = bc.getMethod("build").invoke(b);
            Class<?> gd = Class.forName("android.accessibilityservice.GestureDescription");
            Class<?> cb = Class.forName("android.accessibilityservice.AccessibilityService$GestureResultCallback");
            Object r = AccessibilityService.class.getMethod("dispatchGesture", gd, cb, android.os.Handler.class).invoke(s, g, null, null);
            return Boolean.TRUE.equals(r);
        } catch (Throwable t) { Log.d("CTSS", "gesture: " + t); return false; }
    }

    @Override protected void onServiceConnected() {
        me = this;
        ScreenShare.server(getApplicationContext());
        Log.d("CTAP", "Bedienungshilfe gestartet");
        HotspotBoot.maybe(getApplicationContext());
        if (!getSharedPreferences("ct", 0).getBoolean("apAuto", true) && getSharedPreferences("ct", 0).getBoolean("mapAuto", false) && !MainActivity.alive)
            try { startActivity(new Intent(this, MainActivity.class).addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)); } catch (Throwable t) { }
    }

    @Override public void onInterrupt() { }
}
