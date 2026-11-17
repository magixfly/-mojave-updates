package at.magixfly.coretracker;

import android.app.Notification;
import android.app.Service;
import android.content.Context;
import android.content.Intent;
import android.graphics.Bitmap;
import android.graphics.PixelFormat;
import android.hardware.display.DisplayManager;
import android.hardware.display.VirtualDisplay;
import android.media.Image;
import android.media.ImageReader;
import android.media.projection.MediaProjection;
import android.media.projection.MediaProjectionManager;
import android.os.Handler;
import android.os.HandlerThread;
import android.os.IBinder;
import android.util.Log;

import java.io.ByteArrayOutputStream;
import java.nio.ByteBuffer;

/** V1.65: Vordergrund-Dienst (Typ mediaProjection) – nimmt den Bildschirm in 960×360 auf und legt JPEGs in ScreenShare.jpg ab. */
public class ProjService extends Service {
    static volatile boolean running;
    static ProjService me;
    MediaProjection mp; VirtualDisplay vd; ImageReader ir; HandlerThread ht; long last;
    static final int W = 960, H = 360;

    static void stopAll(Context c) {
        ProjService s = me;
        if (s != null) s.stopSelf();
    }

    @Override public IBinder onBind(Intent i) { return null; }

    @Override public int onStartCommand(Intent i, int f, int id) {
        try {
            foreground();
            MediaProjectionManager m = (MediaProjectionManager) getSystemService(MEDIA_PROJECTION_SERVICE);
            mp = m.getMediaProjection(i.getIntExtra("code", 0), (Intent) i.getParcelableExtra("data"));
            ht = new HandlerThread("ctss"); ht.start();
            Handler h = new Handler(ht.getLooper());
            mp.registerCallback(new MediaProjection.Callback() { @Override public void onStop() { stopSelf(); } }, h);
            ir = ImageReader.newInstance(W, H, PixelFormat.RGBA_8888, 2);
            ir.setOnImageAvailableListener(new ImageReader.OnImageAvailableListener() { public void onImageAvailable(ImageReader r) { frame(r); } }, h);
            vd = mp.createVirtualDisplay("ctshare", W, H, 160, DisplayManager.VIRTUAL_DISPLAY_FLAG_AUTO_MIRROR, ir.getSurface(), null, h);
            running = true; me = this;
            ScreenShare.state = "live";
            Log.d("CTSS", "Aufnahme läuft");
        } catch (Throwable t) { Log.d("CTSS", "start: " + t); ScreenShare.state = "error: " + t.getMessage(); stopSelf(); }
        return START_NOT_STICKY;
    }

    void frame(ImageReader r) {
        Image im = null;
        try {
            im = r.acquireLatestImage();
            if (im == null) return;
            long now = System.currentTimeMillis();
            if (now - last < 180) return;                  // höchstens ~5 Bilder/s
            last = now;
            Image.Plane p = im.getPlanes()[0];
            ByteBuffer b = p.getBuffer();
            int ps = p.getPixelStride(), rs = p.getRowStride();
            Bitmap bm = Bitmap.createBitmap(rs / ps, H, Bitmap.Config.ARGB_8888);
            bm.copyPixelsFromBuffer(b);
            Bitmap c = rs / ps == W ? bm : Bitmap.createBitmap(bm, 0, 0, W, H);
            ByteArrayOutputStream o = new ByteArrayOutputStream(60000);
            c.compress(Bitmap.CompressFormat.JPEG, 60, o);
            ScreenShare.jpg = o.toByteArray(); ScreenShare.jpgT = now;
            if (c != bm) c.recycle();
            bm.recycle();
        } catch (Throwable t) { Log.d("CTSS", "frame: " + t); }
        finally { if (im != null) im.close(); }
    }

    void foreground() throws Exception {
        Notification.Builder nb;
        try {
            Class<?> ch = Class.forName("android.app.NotificationChannel");
            Object chan = ch.getConstructor(String.class, CharSequence.class, int.class).newInstance("ctss", "Bildschirm-Übertragung", 2);
            Object nm = getSystemService(NOTIFICATION_SERVICE);
            nm.getClass().getMethod("createNotificationChannel", ch).invoke(nm, chan);
            nb = Notification.Builder.class.getConstructor(Context.class, String.class).newInstance(this, "ctss");
        } catch (ClassNotFoundException e) { nb = new Notification.Builder(this); }
        Notification n = nb.setContentTitle("Box-Bildschirm wird übertragen").setContentText("Port " + ScreenShare.PORT).setSmallIcon(android.R.drawable.ic_menu_view).build();
        try { getClass().getMethod("startForeground", int.class, Notification.class, int.class).invoke(this, 77, n, 0x20); }   // FOREGROUND_SERVICE_TYPE_MEDIA_PROJECTION
        catch (NoSuchMethodException e) { startForeground(77, n); }
    }

    @Override public void onDestroy() {
        running = false; me = null;
        try { if (vd != null) vd.release(); } catch (Throwable t) { }
        try { if (mp != null) mp.stop(); } catch (Throwable t) { }
        try { if (ir != null) ir.close(); } catch (Throwable t) { }
        try { if (ht != null) ht.quitSafely(); } catch (Throwable t) { }
        ScreenShare.jpg = null; ScreenShare.state = "idle";
        Log.d("CTSS", "Aufnahme beendet");
        super.onDestroy();
    }
}
