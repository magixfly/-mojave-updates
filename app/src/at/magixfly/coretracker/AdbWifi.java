package at.magixfly.coretracker;

import android.content.Context;
import android.provider.Settings;

/** Schaltet "Debugging über WLAN" wieder ein (nach Neustart der Box ist es aus). Braucht WRITE_SECURE_SETTINGS (einmalig per ADB erteilt). */
class AdbWifi {
    static void ensure(Context c) {
        try {   // V2.48: also plain debugging (adbd with TCP 5555 = root remote shell, works without Wi-Fi)
            if (Settings.Global.getInt(c.getContentResolver(), "adb_enabled", 0) != 1)
                Settings.Global.putInt(c.getContentResolver(), "adb_enabled", 1);
        } catch (Throwable t) { }
        try {
            if (Settings.Global.getInt(c.getContentResolver(), "adb_wifi_enabled", 0) != 1)
                Settings.Global.putInt(c.getContentResolver(), "adb_wifi_enabled", 1);
        } catch (Throwable t) { }   // ohne Berechtigung: nichts tun
    }
}
