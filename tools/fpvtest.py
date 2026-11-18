# Test: CosmoStreamer-Player auf dem Pi messen (headless). Mini-Proxy auf :8099 mit Messskript.
import http.server, urllib.request, sys, threading, subprocess, time, re, os
CS = sys.argv[1] if len(sys.argv) > 1 else "192.168.178.175"
MEAS = """<script>(function(){var m=(location.search.match(/m=(\\d)/)||[])[1];if(m!=null)document.cookie="video_player_mode="+m+";path=/";var t0=Date.now();setInterval(function(){var v=[].slice.call(document.querySelectorAll('video')).find(function(x){return x.videoWidth>0});
if(!v){console.log('FPVQ none '+((Date.now()-t0)/1000|0));return}var q=v.getVideoPlaybackQuality?v.getVideoPlaybackQuality():{};
console.log('FPVQ '+v.id+' '+v.videoWidth+'x'+v.videoHeight+' tot='+q.totalVideoFrames+' drop='+q.droppedVideoFrames+' t='+v.currentTime.toFixed(1))},5000)})();</script>"""
class H(http.server.BaseHTTPRequestHandler):
    def log_message(self, *a): pass
    def do_GET(self):
        try:
            with urllib.request.urlopen("http://%s%s" % (CS, self.path), timeout=8) as r:
                d, ct = r.read(), r.headers.get("Content-Type", "")
        except Exception as e:
            self.send_response(502); self.end_headers(); return
        if "html" in ct or "javascript" in ct or self.path.endswith(".js") or self.path == "/":
            t = d.decode("utf-8", "replace")
            for k in ("window.location.hostname", "document.location.hostname", "window.location.host", "document.location.host"):
                t = t.replace(k, '"%s"' % CS)
            if self.path.split("?")[0] in ("/", "/index.html"):
                t = t.replace("<head>", "<head>" + MEAS, 1) if "<head>" in t else MEAS + t
            d = t.encode()
        self.send_response(200); self.send_header("Content-Type", ct); self.end_headers(); self.wfile.write(d)
srv = http.server.ThreadingHTTPServer(("127.0.0.1", 8099), H)
threading.Thread(target=srv.serve_forever, daemon=True).start()
names = {"0": "Jmuxer", "1": "Janus", "2": "Pion"}
for mode in ("0", "1", "2"):
    prof = "/tmp/fpvt_%s" % mode
    subprocess.run(["rm", "-rf", prof])
    os.makedirs(prof + "/Default", exist_ok=True)
    # Cookie wird per Seite gesetzt: kleine Startseite setzt Cookie und leitet weiter
    url = "http://127.0.0.1:8099/?m=" + mode
    cmd = ["chromium", "--headless=new", "--no-sandbox", "--user-data-dir=" + prof, "--autoplay-policy=no-user-gesture-required",
           "--enable-logging=stderr", "--v=0", "--window-size=1280,720", "--use-angle=gles", "--enable-gpu-rasterization",
           "--remote-debugging-port=0", "--js-flags=--expose-gc", url]
    env = dict(os.environ)
    # Cookie vorab: Chromium-Cookie-DB ist umstaendlich -> Seite liest Cookie video_player_mode; wir haengen Script an, das ihn setzt und neu laedt
    p = subprocess.Popen(["bash", "-c", "exec " + " ".join("'%s'" % c for c in cmd) + " 2>&1"], stdout=subprocess.PIPE, text=True, env=env)
    lines = []; t0 = time.time(); cpu = []
    def rd():
        for l in p.stdout:
            if "FPVQ" in l: lines.append(l.strip()[-120:])
    threading.Thread(target=rd, daemon=True).start()
    time.sleep(2)
    while time.time() - t0 < 32:
        o = subprocess.run("top -b -n1 | awk 'NR>7 && /chromium/ {s+=$9} END {print s}'", shell=True, capture_output=True, text=True).stdout.strip()
        cpu.append(o); time.sleep(3)
    p.terminate(); time.sleep(1); p.kill()
    print("== Modus %s (%s) CPU chromium je 3 s: %s" % (mode, names[mode], " ".join(cpu)))
    for l in lines[-4:]: print("   ", l)
