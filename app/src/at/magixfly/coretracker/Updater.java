package at.magixfly.coretracker;

import android.app.PendingIntent;
import android.content.Context;
import android.content.Intent;
import android.content.pm.PackageInstaller;
import android.util.Log;

import java.io.InputStream;
import java.io.OutputStream;
import java.net.HttpURLConnection;
import java.net.URL;

/** V1.52: App aktualisiert sich selbst von GitHub (apk/ver.txt = versionCode), Bedienungshilfe bestätigt. */
class Updater {
    static final String BASE = "https://raw.githubusercontent.com/magixfly/-mojave-updates/carlin/apk/";

    /** V2.05: Stand für den Knopf „Check for update“ im Menü (Text + Prozent für den Balken) */
    static volatile String st = ""; static volatile int pct = -1; static volatile boolean busy = false;
    static void now(final MainActivity a) {
        if (busy) return;
        new Thread(new Runnable() { public void run() {
            try { if (!check(a)) { st = "Up to date (V" + MainActivity.ver(a) + ")"; pct = -1; } }
            catch (Throwable t) { st = "Update failed: " + t.getMessage(); pct = -1; }
        } }).start();
    }

    static void loop(final MainActivity a) {
        new Thread(new Runnable() { public void run() {
            try { Thread.sleep(90000); } catch (Throwable t) { }
            while (true) {
                try { check(a); } catch (Throwable t) { Log.d("CTAP", "update: " + t); st = ""; pct = -1; }
                try { Thread.sleep(30 * 60000L); } catch (Throwable t) { }
            }
        } }).start();
    }

    static String get(String u) throws Exception {
        HttpURLConnection c = (HttpURLConnection) new URL(u + "?t=" + System.currentTimeMillis()).openConnection();
        c.setConnectTimeout(8000); c.setReadTimeout(15000);
        InputStream in = c.getInputStream(); byte[] b = new byte[64]; int n = in.read(b); in.close();
        return n > 0 ? new String(b, 0, n, "UTF-8").trim() : "";
    }

    static synchronized boolean check(MainActivity a) throws Exception {
        busy = true; try { st = "Checking for update …"; pct = 0; return check2(a); } finally { busy = false; }
    }
    static boolean check2(MainActivity a) throws Exception {
        int cur = a.getPackageManager().getPackageInfo(a.getPackageName(), 0).versionCode;
        int neu = Integer.parseInt(get(BASE + "ver.txt"));
        if (neu <= cur) { st = ""; pct = -1; return false; }
        st = "Downloading update …";
        Log.d("CTAP", "Update " + cur + " -> " + neu);
        PackageInstaller pi = a.getPackageManager().getPackageInstaller();
        PackageInstaller.SessionParams sp = new PackageInstaller.SessionParams(PackageInstaller.SessionParams.MODE_FULL_INSTALL);
        int id = pi.createSession(sp);
        PackageInstaller.Session s = pi.openSession(id);
        HttpURLConnection c = (HttpURLConnection) new URL(BASE + "CoreTracker.apk?t=" + System.currentTimeMillis()).openConnection();
        c.setConnectTimeout(8000); c.setReadTimeout(60000);
        long len = c.getContentLength(), got = 0;
        InputStream in = c.getInputStream();
        OutputStream out = s.openWrite("app.apk", 0, -1);
        byte[] buf = new byte[65536]; int r;
        while ((r = in.read(buf)) > 0) { out.write(buf, 0, r); got += r; if (len > 0) pct = (int) Math.min(99, got * 100 / len); }
        s.fsync(out); out.close(); in.close();
        A11y.want("inst");
        Intent i = new Intent(a, MainActivity.class);
        PendingIntent p = PendingIntent.getActivity(a, 7, i, 0x02000000 /*FLAG_MUTABLE*/ | PendingIntent.FLAG_UPDATE_CURRENT);
        s.commit(p.getIntentSender());
        s.close();
        st = "Installing update – the app restarts …"; pct = 100;
        return true;
    }
}
