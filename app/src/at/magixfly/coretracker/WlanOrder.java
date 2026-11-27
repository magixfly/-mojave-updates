package at.magixfly.coretracker;

import android.content.Context;
import android.content.Intent;
import android.os.SystemClock;
import android.util.Log;

import java.util.ArrayList;
import java.util.HashMap;
import java.util.Map;
import java.util.regex.Matcher;
import java.util.regex.Pattern;

/**
 * V1.89: WLAN mit falschem Passwort wird übersprungen. V1.88: WLAN nach fester Reihenfolge (Wunsch Thorsten 23.11.): Media → XVII → Optimus Prime, erst wenn keins da ist
 * eigenen Hotspot (5 GHz) starten. Läuft über die Root-Shell der Box (lokales ADB, siehe HotspotBoot.shell).
 * Passwörter kommen aus den gespeicherten WLANs der Box (WifiConfigStore.xml), werden nie geloggt.
 * Reihenfolge einstellbar in „Box Autostart“ (Pref wlanOrder, Komma-getrennt).
 */
class WlanOrder {
    static final String DEF = "Media,XVII,Optimus Prime";
    static final String STORE = "/data/misc/apexdata/com.android.wifi/WifiConfigStore.xml";
    static volatile boolean watching = false;
    static volatile String state = "";                       // für die Anzeige in Box Autostart
    static final Map<String, Long> failUntil = new HashMap<String, Long>();
    static long lastSwitch = 0, lastAp = 0, noConnSince = 0;

    static String[] order(Context c) {
        String s = c.getSharedPreferences("ct", 0).getString("wlanOrder", DEF);
        ArrayList<String> l = new ArrayList<String>();
        for (String x : s.split(",")) if (x.trim().length() > 0) l.add(x.trim());
        return l.toArray(new String[0]);
    }

    static String sh(String cmd) { try { return HotspotBoot.shell(cmd); } catch (Throwable t) { Log.d("CTWL", "shell: " + t); return ""; } }

    /** verbundenes WLAN (oder "") */
    static String current() {
        Matcher m = Pattern.compile("connected to \"(.*)\"").matcher(sh("cmd wifi status"));
        return m.find() ? m.group(1) : "";
    }

    /** sichtbare WLANs: SSID → bester RSSI */
    static Map<String, Integer> scan() {
        Map<String, Integer> v = new HashMap<String, Integer>();
        String out = sh("cmd wifi start-scan; sleep 4; cmd wifi list-scan-results");
        Pattern p = Pattern.compile("^\\s*([0-9a-f]{2}(?::[0-9a-f]{2}){5})\\s+(\\d+)\\s+(-?\\d+)\\S*\\s+\\S+\\s+(.*?)\\s*(\\[.*)?$");
        for (String l : out.split("\n")) {
            Matcher m = p.matcher(l);
            if (!m.find()) continue;
            String ssid = m.group(4).trim(); int r = Integer.parseInt(m.group(3));
            if (ssid.length() == 0) continue;
            Integer o = v.get(ssid); if (o == null || r > o) v.put(ssid, r);
        }
        return v;
    }

    static String unx(String s) { return s.replace("&quot;", "\"").replace("&apos;", "'").replace("&lt;", "<").replace("&gt;", ">").replace("&amp;", "&"); }

    /** gespeicherte WLANs der Box: SSID → Passwort ("" = offen/unbekannt) */
    static Map<String, String> saved() {
        Map<String, String> s = new HashMap<String, String>();
        String x = sh("cat " + STORE);
        for (String n : x.split("<Network>")) {
            Matcher a = Pattern.compile("<string name=\"SSID\">([^<]*)</string>").matcher(n);
            if (!a.find()) continue;
            String ssid = unx(a.group(1)); if (ssid.startsWith("\"") && ssid.endsWith("\"")) ssid = ssid.substring(1, ssid.length() - 1);
            Matcher k = Pattern.compile("<string name=\"PreSharedKey\">([^<]*)</string>").matcher(n);
            String psk = k.find() ? unx(k.group(1)) : "";
            if (psk.startsWith("\"") && psk.endsWith("\"")) psk = psk.substring(1, psk.length() - 1); else psk = "";
            if (n.contains("WRONG_PASSWORD")) { Log.d("CTWL", ssid + ": falsches Passwort gespeichert -> überspringen"); continue; }   // V1.89
            if (!s.containsKey(ssid) || s.get(ssid).length() == 0) s.put(ssid, psk);
        }
        return s;
    }

    static String q(String s) { return "'" + s.replace("'", "'\\''") + "'"; }

    /** mit SSID verbinden, bis 30 s warten */
    static boolean connect(String ssid, String psk) {
        Log.d("CTWL", "verbinde " + ssid);
        state = "verbinde " + ssid + " …";
        sh("cmd wifi connect-network " + q(ssid) + (psk.length() > 0 ? " wpa2 " + q(psk) : " open"));
        for (int i = 0; i < 15; i++) {
            SystemClock.sleep(2000);
            if (ssid.equals(current())) { lastSwitch = SystemClock.elapsedRealtime(); state = "WLAN " + ssid; return true; }
        }
        failUntil.put(ssid, SystemClock.elapsedRealtime() + 60 * 60 * 1000L);   // V1.89: 1 h Pause (falsches Passwort wirft die Box sonst immer kurz raus)
        Log.d("CTWL", ssid + " fehlgeschlagen");
        return false;
    }

    /** Bestes WLAN nach Reihenfolge wählen. true = mit einem WLAN verbunden. */
    static boolean pick(Context c) {
        String[] ord = order(c);
        String cur = current();
        Map<String, Integer> vis = scan();
        Map<String, String> sv = saved();
        long now = SystemClock.elapsedRealtime();
        for (String s : ord) {
            if (s.equals(cur)) { state = "WLAN " + cur; return true; }          // schon im besten verfügbaren
            Integer r = vis.get(s);
            Long f = failUntil.get(s);
            if (r == null || r < -82 || !sv.containsKey(s) || (f != null && f > now)) continue;
            if (connect(s, sv.get(s))) return true;
        }
        cur = current();
        if (cur.length() > 0) state = "WLAN " + cur;
        return cur.length() > 0;
    }

    static void startAp(Context c) {
        lastAp = SystemClock.elapsedRealtime();
        state = "kein WLAN → Hotspot";
        Log.d("CTWL", "kein WLAN aus der Liste → Hotspot");
        A11y.want("ap");
        try { c.startActivity(new Intent("android.settings.TETHER_SETTINGS").addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)); } catch (Throwable t) { Log.d("CTWL", "ap: " + t); }
    }

    /** Beim Start: WLANs der Reihe nach probieren (bis ~1 min), sonst Hotspot. */
    static void boot(Context c) {
        for (int i = 0; i < 2; i++) {   // V2.70: 2 tries 5 s apart (was 3 x 10 s) - hotspot comes about 40 s earlier
            if (HotspotBoot.apOn(c)) return;
            if (pick(c)) return;
            SystemClock.sleep(5000);
        }
        if (c.getSharedPreferences("ct", 0).getBoolean("apAuto", true) && !HotspotBoot.apOn(c)) startAp(c);
    }

    /** Läuft dauerhaft: jede Minute prüfen – besseres WLAN in Reichweite → wechseln; 2 min kein WLAN → Liste probieren, dann Hotspot. */
    static void watch(final Context c) {
        if (watching) return;
        watching = true;
        new Thread(new Runnable() { public void run() {
            while (true) {
                SystemClock.sleep(60000);
                try {
                    if (!c.getSharedPreferences("ct", 0).getBoolean("wlanAuto", true)) continue;
                    if (HotspotBoot.apOn(c)) { noConnSince = 0; state = "Hotspot an"; continue; }
                    long now = SystemClock.elapsedRealtime();
                    String cur = current();
                    String[] ord = order(c);
                    if (cur.length() > 0) {
                        noConnSince = 0;
                        state = "WLAN " + cur;
                        if (ord.length > 0 && ord[0].equals(cur)) continue;                   // schon das erste
                        if (now - lastSwitch < 5 * 60 * 1000L) continue;                      // nicht hin und her springen
                        pick(c);
                    } else {
                        if (noConnSince == 0) noConnSince = now;
                        if (now - noConnSince < 2 * 60 * 1000L) continue;
                        if (pick(c)) { noConnSince = 0; continue; }
                        if (c.getSharedPreferences("ct", 0).getBoolean("apAuto", true) && now - lastAp > 10 * 60 * 1000L) startAp(c);
                    }
                } catch (Throwable t) { Log.d("CTWL", "watch: " + t); }
            }
        } }).start();
    }
}
