package at.magixfly.coretracker;
import java.io.OutputStream;
import java.net.HttpURLConnection;
import java.net.URL;
/** V1.25: sends the map download status to the tracker (POST /api/box); answer "toggle":1 = stop/start (tap on the PC/phone). */
class Report implements Runnable {
    final MainActivity a; final String base, txt, net; final boolean on, stop; final double gb, est;
    Report(MainActivity a, String base, String txt, boolean on, double gb, double est, String net, boolean stop) {
        this.a = a; this.base = base; this.txt = txt; this.on = on; this.gb = gb; this.est = est; this.net = net; this.stop = stop;
    }
    static String q(String s) { return s == null ? "null" : "\"" + s.replace("\\", "\\\\").replace("\"", "\\\"") + "\""; }
    public void run() {
        try {
            String j = "{\"txt\":" + q(txt) + ",\"dl\":" + (on ? 1 : 0) + ",\"gb\":" + String.format(java.util.Locale.US, "%.2f", gb)
                    + ",\"est\":" + String.format(java.util.Locale.US, "%.1f", est) + ",\"net\":" + q(net) + ",\"stop\":" + (stop ? 1 : 0) + ",\"ver\":\"1.25\"}";
            HttpURLConnection c = (HttpURLConnection) new URL(base + "/api/box").openConnection();
            c.setConnectTimeout(1500); c.setReadTimeout(2000); c.setDoOutput(true);
            c.setRequestMethod("POST"); c.setRequestProperty("Content-Type", "application/json");
            byte[] d = j.getBytes("UTF-8");
            c.setRequestProperty("Content-Length", String.valueOf(d.length));
            OutputStream o = c.getOutputStream(); o.write(d); o.close();
            java.io.InputStream in = c.getInputStream();
            byte[] r = new byte[256]; int n = in.read(r); in.close(); c.disconnect();
            if (n > 0 && new String(r, 0, n, "UTF-8").replace(" ", "").contains("\"toggle\":1")) {
                a.tiles.setStopped(!a.tiles.stopped);
                a.ui.post(new Task(a, Task.PILL, null, 0));
            }
        } catch (Throwable t) { }
    }
}
