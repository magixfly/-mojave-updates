package at.magixfly.coretracker;
import java.util.concurrent.atomic.AtomicReference;
/** V1.24: one address of the network scan */
class Scan implements Runnable {
    final String h; final AtomicReference<String> hit;
    Scan(String h, AtomicReference<String> hit) { this.h = h; this.hit = hit; }
    public void run() { if (hit.get() == null && MainActivity.ok(h)) hit.compareAndSet(null, h); }
}
