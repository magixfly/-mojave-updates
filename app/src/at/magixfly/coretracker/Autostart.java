package at.magixfly.coretracker;

import android.app.Activity;
import android.content.Intent;
import android.content.SharedPreferences;
import android.graphics.Typeface;
import android.os.Bundle;
import android.view.Gravity;
import android.view.View;
import android.widget.CompoundButton;
import android.widget.LinearLayout;
import android.widget.ScrollView;
import android.widget.Switch;
import android.widget.TextView;

/** V1.59: eigenes Programm „Box Autostart“ (eigenes Symbol): Startoptionen der Box ein/aus + „Jetzt ausführen“. */
public class Autostart extends Activity {
    static volatile Class<?> backTo = null;
    static volatile boolean forceBand = false;
    SharedPreferences p;
    TextView st;

    static final String[][] OPT = {
        {"apAuto", "1", "Hotspot beim Start einschalten"},
        {"ap5", "1", "Hotspot auf 5 GHz festlegen"},
        {"adbAuto", "1", "Debugging über WLAN (ADB) beim Start – Fernwartung"},
        {"mapAuto", "0", "Core Tracker (Karte) beim Start öffnen"},
    };

    @Override protected void onCreate(Bundle b) {
        super.onCreate(b);
        p = getSharedPreferences("ct", 0);
        LinearLayout l = new LinearLayout(this);
        l.setOrientation(LinearLayout.VERTICAL);
        l.setPadding(60, 30, 60, 30);
        l.setBackgroundColor(0xFF0B0F14);
        TextView h = tv("Box Autostart", 30, 0xFF4ADE80); h.setTypeface(null, Typeface.BOLD); l.addView(h);
        for (final String[] o : OPT) {
            Switch s = new Switch(this);
            s.setText(o[2]); s.setTextSize(22); s.setTextColor(0xFFE5E7EB);
            s.setPadding(0, 22, 0, 22);
            s.setChecked(p.getBoolean(o[0], o[1].equals("1")));
            s.setOnCheckedChangeListener(new CompoundButton.OnCheckedChangeListener() {
                public void onCheckedChanged(CompoundButton v, boolean on) { p.edit().putBoolean(o[0], on).apply(); status(); }
            });
            l.addView(s);
        }
        TextView go = tv("Jetzt ausführen (Hotspot an + 5 GHz)", 22, 0xFF4ADE80);
        go.setGravity(Gravity.CENTER); go.setTypeface(null, Typeface.BOLD);
        android.graphics.drawable.GradientDrawable g = new android.graphics.drawable.GradientDrawable();
        g.setColor(0xFF0B0F14); g.setStroke(3, 0x994DB8FF); g.setCornerRadius(14);
        go.setBackground(g); go.setPadding(20, 24, 20, 24);
        LinearLayout.LayoutParams gl = new LinearLayout.LayoutParams(-1, -2); gl.topMargin = 24;
        l.addView(go, gl);
        go.setOnClickListener(new View.OnClickListener() { public void onClick(View v) { runNow(); } });
        st = tv("", 20, 0xFF9CA3AF); st.setPadding(0, 24, 0, 0); l.addView(st);
        ScrollView sv = new ScrollView(this); sv.addView(l); sv.setBackgroundColor(0xFF0B0F14);
        setContentView(sv);
        A11y.enable(this);
    }

    @Override protected void onResume() { super.onResume(); status(); }

    TextView tv(String t, int sp, int col) { TextView v = new TextView(this); v.setText(t); v.setTextSize(sp); v.setTextColor(col); return v; }

    void status() {
        if (st == null) return;
        boolean on = HotspotBoot.apOn(this);
        st.setText("Hotspot: " + (on ? "an" + band() : "aus") + "\nApp-Version " + ver());
    }

    String ver() { try { return getPackageManager().getPackageInfo(getPackageName(), 0).versionName; } catch (Throwable t) { return "?"; } }

    String band() {
        try {
            Object wm = getApplicationContext().getSystemService(WIFI_SERVICE);
            try {
                Object c = wm.getClass().getMethod("getSoftApConfiguration").invoke(wm);
                int b = (Integer) c.getClass().getMethod("getBand").invoke(c);
                return (b & 3) == 2 ? ", 5 GHz" : (b & 3) == 1 ? ", 2,4 GHz" : (b & 3) == 3 ? ", 2,4 + 5 GHz" : "";
            } catch (NoSuchMethodException e) { }
            Object c = wm.getClass().getMethod("getWifiApConfiguration").invoke(wm);
            int b = c.getClass().getField("apBand").getInt(c);
            return b == 1 ? ", 5 GHz" : b == 0 ? ", 2,4 GHz" : "";
        } catch (Throwable t) { return ""; }
    }

    void runNow() {
        backTo = Autostart.class;                         // danach wieder hierher
        forceBand = true;
        if (!HotspotBoot.apOn(this)) {
            A11y.want("ap");
            startActivity(new Intent("android.settings.TETHER_SETTINGS").addFlags(Intent.FLAG_ACTIVITY_NEW_TASK));
        } else if (p.getBoolean("ap5", true)) A11y.startBand(this, true);
        else backTo = null;
    }
}
