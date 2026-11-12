package at.magixfly.coretracker;
import android.view.View;
import android.webkit.WebView;
import android.webkit.WebViewClient;
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
    }
}
