package at.magixfly.coretracker;
import java.io.File;
/** V2.06: lädt die Kacheln der Gebietsliste (Zentrale → Pi → basemap.at). Im Hintergrund nur über WLAN, nie über die SIM-Karte. */
class TileWorker implements Runnable {
    final TileStore s;
    TileWorker(TileStore s) { this.s = s; }
    /** V2.65: Wi-Fi always; over the SIM (LTE) only tiles of "load first" areas */
    boolean netOk(long[] t) {
        String n = s.netType();
        if ("Wi-Fi".equals(n)) return true;
        return n != null && t.length > 3 && t[3] == 1 && s.a.prefs.getBoolean("ltePrio", true);
    }

    public void run() {
        while (true) {
            try {
                long[] t = s.q.take();
                if (t[0] < 0) { if (s.q.isEmpty() && !s.finished) { s.finished = true; s.a.prefs.edit().putString("mapsDone", s.curTag).apply(); } continue; }   // V2.71: remember "complete" for this list
                while (s.stopped || s.full || !netOk(t)) {
                    s.paused = true;
                    s.full = s.dir.getUsableSpace() < TileStore.KEEP_FREE;
                    Thread.sleep(2000);
                }
                s.paused = false;
                int z = (int) t[0], x = (int) t[1], y = (int) t[2];
                File f = s.file(z, x, y);
                if (!f.exists()) {
                    byte[] d = s.fetch(z, x, y, false, 8000);
                    if (d != null) {
                        TileStore.save(f, d);                                   // 0 Byte = keine Daten an dieser Stelle
                        if (d.length > 0) { s.loaded.incrementAndGet(); s.bytes.addAndGet(d.length); s.lastOk = System.currentTimeMillis(); }
                    }
                    File o = s.ovlFile(z, x, y);
                    if (!o.exists()) { byte[] od = s.fetch(z, x, y, true, 8000); if (od != null) TileStore.save(o, od); }
                }
                s.done.incrementAndGet();
                if ((s.done.get() & 255) == 0) { s.full = s.dir.getUsableSpace() < TileStore.KEEP_FREE; s.saveTotal(); }
            } catch (Throwable e) { try { Thread.sleep(1000); } catch (Throwable t) { } }
        }
    }
}
