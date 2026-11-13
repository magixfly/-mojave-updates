package at.magixfly.coretracker;

import android.content.BroadcastReceiver;
import android.content.Context;
import android.content.Intent;

/** Beim Start der Box: Debugging über WLAN einschalten, damit der Pi die Box wieder erreicht. */
public class BootReceiver extends BroadcastReceiver {
    @Override
    public void onReceive(Context c, Intent i) { AdbWifi.ensure(c); }
}
