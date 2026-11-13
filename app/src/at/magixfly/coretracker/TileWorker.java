package at.magixfly.coretracker;
import java.io.File;
class TileWorker implements Runnable {
    final TileStore s;
    TileWorker(TileStore s) { this.s = s; }
        public void run() {
            try {
                while (true) {
                    long[] t = s.q.take();
                    if (t[0] < 0) { s.finished = true; return; }
                    while (!s.onWifi() || s.full) {
                        s.paused = true;
                        s.full = s.dir.getUsableSpace() < TileStore.KEEP_FREE;
                        Thread.sleep(30000);
                    }
                    s.paused = false;
                    int z = (int) t[0], x = (int) t[1], y = (int) t[2];
                    File f = s.file(z, x, y);
                    byte[] d = TileStore.http(String.format(TileStore.SRC, z, y, x), 8000);
                    if (d != null) {
                        TileStore.save(f, d);                                   // 0 Byte = keine Daten an dieser Stelle
                        if (d.length > 0) { s.loaded.incrementAndGet(); s.bytes.addAndGet(d.length); }
                    }
                    s.done.incrementAndGet();
                    if ((s.done.get() & 255) == 0) s.full = s.dir.getUsableSpace() < TileStore.KEEP_FREE;
                }
            } catch (Throwable e) { }
        }
    }

