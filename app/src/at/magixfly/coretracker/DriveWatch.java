package at.magixfly.coretracker;

import java.util.regex.Matcher;
import java.util.regex.Pattern;

/** Fragt beim Pi alle 2 s die Geschwindigkeit ab. Fährt ein Modell (> 2 km/h), pausiert der Vorab-Download bis 60 s nach Stillstand. */
class DriveWatch implements Runnable {
    static final Pattern SPD = Pattern.compile("\"spd\"\\s*:\\s*(-?[0-9.]+)");
    final TileStore s;
    DriveWatch(TileStore s) { this.s = s; }
    public void run() {
        int n = 0;
        while (true) {
            try {
                String base = s.a.piBase;
                if (base != null) {
                    byte[] d = TileStore.http(base + "/api/state", 2000);
                    if (d != null && d.length > 0) {
                        Matcher m = SPD.matcher(new String(d, "UTF-8"));
                        boolean moving = false;
                        while (m.find()) if (Double.parseDouble(m.group(1)) > 2.0) moving = true;
                        if (moving) s.lastMove = System.currentTimeMillis();
                    }
                }
                s.driving = System.currentTimeMillis() - s.lastMove < 60000;
                if ((++n % 15) == 0) AdbWifi.ensure(s.a);       // alle 30 s prüfen
                Thread.sleep(2000);
            } catch (Throwable t) {
                try { Thread.sleep(2000); } catch (Throwable u) { }
            }
        }
    }
}
