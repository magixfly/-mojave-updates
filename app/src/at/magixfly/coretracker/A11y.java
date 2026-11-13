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
        new android.os.Handler(getMainLooper()).postDelayed(new Runnable() { public void run() {
            Intent i = new Intent(A11y.this, MainActivity.class).addFlags(Intent.FLAG_ACTIVITY_NEW_TASK | Intent.FLAG_ACTIVITY_REORDER_TO_FRONT);
            startActivity(i);
        } }, 2500);
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

    @Override public void onInterrupt() { }
}
