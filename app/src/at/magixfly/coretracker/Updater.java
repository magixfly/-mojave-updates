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

    static void loop(final MainActivity a) {
        new Thread(new Runnable() { public void run() {
            try { Thread.sleep(90000); } catch (Throwable t) { }
            while (true) {
                try { check(a); } catch (Throwable t) { Log.d("CTAP", "update: " + t); }
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

    static void check(MainActivity a) throws Exception {
        int cur = a.getPackageManager().getPackageInfo(a.getPackageName(), 0).versionCode;
        int neu = Integer.parseInt(get(BASE + "ver.txt"));
        if (neu <= cur) return;
        Log.d("CTAP", "Update " + cur + " -> " + neu);
        PackageInstaller pi = a.getPackageManager().getPackageInstaller();
        PackageInstaller.SessionParams sp = new PackageInstaller.SessionParams(PackageInstaller.SessionParams.MODE_FULL_INSTALL);
        int id = pi.createSession(sp);
        PackageInstaller.Session s = pi.openSession(id);
        HttpURLConnection c = (HttpURLConnection) new URL(BASE + "CoreTracker.apk?t=" + System.currentTimeMillis()).openConnection();
        c.setConnectTimeout(8000); c.setReadTimeout(60000);
        InputStream in = c.getInputStream();
        OutputStream out = s.openWrite("app.apk", 0, -1);
        byte[] buf = new byte[65536]; int r;
        while ((r = in.read(buf)) > 0) out.write(buf, 0, r);
        s.fsync(out); out.close(); in.close();
        A11y.want("inst");
        Intent i = new Intent(a, MainActivity.class);
        PendingIntent p = PendingIntent.getActivity(a, 7, i, 0x02000000 /*FLAG_MUTABLE*/ | PendingIntent.FLAG_UPDATE_CURRENT);
        s.commit(p.getIntentSender());
        s.close();
    }
}
