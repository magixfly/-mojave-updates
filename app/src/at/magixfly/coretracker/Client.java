package at.magixfly.coretracker;
import android.view.View;
import android.webkit.WebView;
import android.webkit.WebViewClient;
import android.webkit.WebResourceResponse;
class Client extends WebViewClient {
    final MainActivity a;
    Client(MainActivity a) { this.a = a; }
    @Override
    public void onReceivedError(WebView v, int code, String desc, String url) {
        a.loaded = false;
        a.showOverlay("Verbindung zum Tracker verloren – suche neu …", 0);
        a.ui.postDelayed(new Task(a, Task.SEARCH, null, 0), 2000);
    }
    @Override
    public void onPageFinished(WebView v, String url) {
        if (a.loaded) a.overlay.setVisibility(View.GONE);
        v.evaluateJavascript(MainActivity.CSS_JS, null);
    }

    /** Kartenkacheln aus dem Speicher der Box liefern (schnell), sonst vom Pi holen und merken. */
    @Override
    public WebResourceResponse shouldInterceptRequest(WebView v, String url) {
        try {
            int i = url.indexOf("/tile/");
            if (i < 0 || a.tiles == null) return null;
            String[] p = url.substring(i + 6).split("[/?.]");
            int z = Integer.parseInt(p[0]), x = Integer.parseInt(p[1]), y = Integer.parseInt(p[2]);
            byte[] d = a.tiles.get(z, x, y, a.piBase);
            if (d == null) return null;
            return new WebResourceResponse("image/jpeg", null, new java.io.ByteArrayInputStream(d));
        } catch (Throwable t) { return null; }
    }
}
