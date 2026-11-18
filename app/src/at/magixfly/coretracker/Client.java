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
        a.showOverlay("Connection to the tracker lost – searching …", 0);
        a.ui.postDelayed(new Task(a, Task.SEARCH, null, 0), 2000);
    }
    @Override
    public void onPageFinished(WebView v, String url) {
        if (a.loaded) a.overlay.setVisibility(View.GONE);
        v.evaluateJavascript(MainActivity.CSS_JS, null);
        // V1.61: neben „CORE TRACKER“ zwei Zeilen: Box-Version über Tracker-Version
        // V1.75: Menü-Einträge der Box: FPV-Player, App neu starten, App schließen
        v.evaluateJavascript("(function(){function f(){var t=document.getElementById('mTheme');if(!t)return;var L=[['mCtPl','FPV player: " + (a.fpv != null ? a.fpv.playerName() : "Janus") + "','player'],['mCtRe','Restart app','restart'],['mCtCl','Close app','close']];var at=t;L.forEach(function(x){var b=document.getElementById(x[0]);if(!b){b=document.createElement('button');b.className='mb';b.id=x[0];b.onclick=function(){fetch('/__ctbox/'+x[2]);if(x[2]=='player')setTimeout(function(){b.textContent='FPV player: '+({'FPV player: Janus':'Pion','FPV player: Pion':'Jmuxer','FPV player: Jmuxer':'Janus'})[b.textContent]},50)};at.parentNode.insertBefore(b,at.nextSibling);b.textContent=x[1];}at=b;});var pl=document.getElementById('mPlayer');if(pl)pl.style.display='none';}f();if(!window.ctMenuT)window.ctMenuT=setInterval(f,3000);})()", null);
        v.evaluateJavascript("(function(){function f(){var e=document.getElementById('ver');if(!e)return;e.dataset.box='Box " + Report.ver(a) + "';var t=e.textContent||'';if(/^V\\d/.test(t))e.textContent='Tracker '+t;}f();if(!window.ctVerT)window.ctVerT=setInterval(f,3000);})()", null);
    }

    /** Kartenkacheln aus dem Speicher der Box liefern (schnell), sonst vom Pi holen und merken. */
    @Override
    public WebResourceResponse shouldInterceptRequest(WebView v, String url) {
        try {
            if (url.contains("/__ctbox/player")) {         // V1.75: FPV-Player wechseln (Janus → Pion → Jmuxer)
                if (a.fpv != null) a.fpv.nextPlayer();
                return new WebResourceResponse("text/plain", null, new java.io.ByteArrayInputStream(new byte[0]));
            }
            if (url.contains("/__ctbox/restart") || url.contains("/__ctbox/close")) {   // V1.75: App neu starten / schließen
                final boolean re = url.contains("restart");
                a.ui.postDelayed(new Runnable() { public void run() { MainActivity.quit(a, re); } }, 200);
                return new WebResourceResponse("text/plain", null, new java.io.ByteArrayInputStream(new byte[0]));
            }
            if (url.contains("/__ctbox/toggle")) {         // V1.22: tap on "Maps" = stop / start the download
                a.tiles.setStopped(!a.tiles.stopped);
                a.ui.post(new Task(a, Task.PILL, null, 0));
                return new WebResourceResponse("text/plain", null, new java.io.ByteArrayInputStream(new byte[0]));
            }
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
