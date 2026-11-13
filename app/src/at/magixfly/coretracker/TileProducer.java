package at.magixfly.coretracker;
import java.io.File;
class TileProducer implements Runnable {
    final TileStore s;
    TileProducer(TileStore s) { this.s = s; }
        public void run() {
            try {
                for (int z = TileStore.ZMIN; z <= TileStore.ZFULL; z++) {
                    s.phase = "Zoom " + z;
                    for (long x = TileStore.lonX(TileStore.LON_W, z); x <= TileStore.lonX(TileStore.LON_E, z); x++)
                        for (long y = TileStore.latY(TileStore.LAT_N, z); y <= TileStore.latY(TileStore.LAT_S, z); y++) offer(z, x, y);
                }
                // Zoom 17 + 18 ringförmig um St. Pölten
                long cx = TileStore.lonX(TileStore.C_LON, 17), cy = TileStore.latY(TileStore.C_LAT, 17);
                long x0 = TileStore.lonX(TileStore.LON_W, 17), x1 = TileStore.lonX(TileStore.LON_E, 17), y0 = TileStore.latY(TileStore.LAT_N, 17), y1 = TileStore.latY(TileStore.LAT_S, 17);
                long rMax = Math.max(Math.max(cx - x0, x1 - cx), Math.max(cy - y0, y1 - cy));
                for (long r = 0; r <= rMax; r++) {
                    s.phase = "Zoom 17/18 · " + (r * 100 / Math.max(1, rMax)) + " % of the area";
                    for (long x = cx - r; x <= cx + r; x++)
                        for (long y = cy - r; y <= cy + r; y++) {
                            if (Math.max(Math.abs(x - cx), Math.abs(y - cy)) != r) continue;
                            if (x < x0 || x > x1 || y < y0 || y > y1) continue;
                            offer(17, x, y);
                            for (int dx = 0; dx < 2; dx++) for (int dy = 0; dy < 2; dy++) offer(18, 2 * x + dx, 2 * y + dy);
                        }
                }
                for (int i = 0; i < TileStore.WORKERS; i++) s.q.put(new long[]{-1, 0, 0});
            } catch (Throwable t) { }
        }

        void offer(int z, long x, long y) throws InterruptedException {
            if (s.full) { Thread.sleep(60000); }
            File f = s.file(z, (int) x, (int) y);
            if (f.exists()) { s.done.incrementAndGet(); return; }      // schon da (oder ohne Daten markiert)
            s.q.put(new long[]{z, x, y});
        }
    }

