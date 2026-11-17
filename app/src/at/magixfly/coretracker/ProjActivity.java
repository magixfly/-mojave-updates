package at.magixfly.coretracker;

import android.app.Activity;
import android.content.Intent;
import android.os.Bundle;
import android.util.Log;

/** V1.65: unsichtbar – fragt die Erlaubnis zur Bildschirmaufnahme an und startet den Aufnahmedienst. */
public class ProjActivity extends Activity {
    @Override protected void onCreate(Bundle b) {
        super.onCreate(b);
        try {
            Object mgr = getSystemService("media_projection");
            Intent i;
            try {   // Android 14+: gleich den ganzen Bildschirm (keine Auswahl „einzelne App“)
                Class<?> cfg = Class.forName("android.media.projection.MediaProjectionConfig");
                Object c = cfg.getMethod("createConfigForDefaultDisplay").invoke(null);
                i = (Intent) mgr.getClass().getMethod("createScreenCaptureIntent", cfg).invoke(mgr, c);
            } catch (Throwable t) {
                i = (Intent) mgr.getClass().getMethod("createScreenCaptureIntent").invoke(mgr);
            }
            startActivityForResult(i, 7);
        } catch (Throwable t) { Log.d("CTSS", "proj: " + t); ScreenShare.state = "error: " + t; finish(); }
    }

    @Override protected void onActivityResult(int req, int res, Intent data) {
        if (req == 7 && res == RESULT_OK && data != null) {
            ScreenShare.state = "starting";
            Intent s = new Intent(this, ProjService.class).putExtra("code", res).putExtra("data", data);
            try { getClass().getMethod("startForegroundService", Intent.class).invoke(this, s); }
            catch (Throwable t) { startService(s); }
        } else ScreenShare.state = "denied";
        finish();
        overridePendingTransition(0, 0);
    }
}
