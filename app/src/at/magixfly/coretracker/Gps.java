package at.magixfly.coretracker;

import android.location.Location;
import android.location.LocationListener;
import android.location.LocationManager;
import android.os.Bundle;

/** V2.01: eigene Position der Box (GPS bzw. Netzwerk, falls die Box das hat) für die Karte. Berechtigung holt sich die App über die Root-Shell. */
class Gps implements LocationListener {
    final MainActivity a;
    volatile Location last;
    LocationManager lm;
    Gps(MainActivity a) { this.a = a; }

    void start() {
        new Thread(new Runnable() { public void run() {
            try {
                if (a.checkSelfPermission("android.permission.ACCESS_FINE_LOCATION") != 0)
                    HotspotBoot.shell("pm grant at.magixfly.coretracker android.permission.ACCESS_FINE_LOCATION; pm grant at.magixfly.coretracker android.permission.ACCESS_COARSE_LOCATION");
            } catch (Throwable t) { android.util.Log.d("CTGPS", "grant: " + t); }
            a.ui.post(new Runnable() { public void run() { listen(); } });
        } }).start();
    }

    void listen() {
        try {
            lm = (LocationManager) a.getSystemService(android.content.Context.LOCATION_SERVICE);
            String[] pr = {LocationManager.GPS_PROVIDER, LocationManager.NETWORK_PROVIDER};
            for (String p : pr) {
                try {
                    if (!lm.getAllProviders().contains(p)) continue;
                    Location l = lm.getLastKnownLocation(p);
                    if (l != null && (last == null || l.getTime() > last.getTime())) last = l;
                    lm.requestLocationUpdates(p, 1000, 0, this);
                    android.util.Log.d("CTGPS", "listening " + p);
                } catch (Throwable t) { android.util.Log.d("CTGPS", p + ": " + t); }
            }
            push();
        } catch (Throwable t) { android.util.Log.d("CTGPS", "listen: " + t); }
    }

    void stop() { try { if (lm != null) lm.removeUpdates(this); } catch (Throwable t) { } }

    void push() {
        Location l = last;
        if (l == null) return;
        boolean gps = LocationManager.GPS_PROVIDER.equals(l.getProvider());
        a.js("window.ctPos&&ctPos(" + l.getLatitude() + "," + l.getLongitude() + "," + (l.hasAccuracy() ? l.getAccuracy() : -1) + ","
                + (l.hasSpeed() ? l.getSpeed() * 3.6 : -1) + "," + (l.hasBearing() ? l.getBearing() : -1) + "," + (System.currentTimeMillis() - l.getTime()) / 1000 + "," + gps + ")");
    }

    public void onLocationChanged(Location l) {
        Location o = last;
        // GPS hat Vorrang; Netzwerk-Position nur, wenn GPS älter als 10 s ist
        if (o != null && LocationManager.GPS_PROVIDER.equals(o.getProvider()) && !LocationManager.GPS_PROVIDER.equals(l.getProvider())
                && l.getTime() - o.getTime() < 10000) return;
        last = l;
        push();
    }
    public void onStatusChanged(String p, int s, Bundle b) { }
    public void onProviderEnabled(String p) { }
    public void onProviderDisabled(String p) { }
}
