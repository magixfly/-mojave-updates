package at.magixfly.coretracker;

import android.util.Log;

/** V2.73: on this box the radio start script (init.class_main.sh) sometimes does not run at boot -> no RIL daemon,
 *  com.android.phone hangs and restarts every 15 s, no SIM, Wi-Fi/SIM settings crash. If the RIL daemon is not running
 *  25 s after start: start netmgrd, run the script (qcrild + qcrild2 for dual SIM), restart the RIL daemons, then the phone process. */
class RadioFix {
    static volatile boolean done = false;

    static void maybe() {
        if (done) return;
        done = true;
        new Thread() { public void run() {
            try {
                Thread.sleep(25000);
                String st = HotspotBoot.shell("getprop init.svc.vendor.qcrild").trim();
                Log.d("CTRAD", "qcrild=" + st);
                if (st.equals("running")) return;
                HotspotBoot.shell("pidof netmgrd >/dev/null || (setsid /vendor/bin/netmgrd </dev/null >/dev/null 2>&1 &)");
                Thread.sleep(5000);
                HotspotBoot.shell("sh /vendor/bin/init.class_main.sh >/dev/null 2>&1");
                Thread.sleep(4000);
                HotspotBoot.shell("stop vendor.qcrild2; stop vendor.qcrild; sleep 2; start vendor.qcrild; start vendor.qcrild2");
                Thread.sleep(4000);
                HotspotBoot.shell("kill $(pidof com.android.phone)");
                Log.d("CTRAD", "radio started by the app");
            } catch (Throwable t) { Log.d("CTRAD", "fix: " + t); }
        } }.start();
    }
}
