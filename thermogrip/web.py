# THERMOGRIP – WLAN + Webseite (Einstellungen aendern, Firmware-Update ueber WLAN)
# Wird von main.py nur geladen, wenn wifi_enable = 1.
import network, socket, time, os, gc, json

ALLOWED = ("main.py", "fonts.bin", "web.py", "web.html", "config.txt")


def _cfg_lines():
    out = []
    for line in open("config.txt").read().split("\n"):
        s = line.strip()
        if not s or s.startswith("#") or "=" not in s:
            continue
        body, _, com = s.partition("#")
        k, _, v = body.partition("=")
        out.append([k.strip(), v.strip(), com.strip()])
    return out


def _cfg_write(new):
    lines = open("config.txt").read().split("\n")
    for i, line in enumerate(lines):
        s = line.strip()
        if not s or s.startswith("#") or "=" not in s:
            continue
        body, _, com = s.partition("#")
        k = body.partition("=")[0].strip()
        if k in new:
            v = str(new[k]).replace("#", "").replace("\n", "").strip()
            lines[i] = "%-17s = %-5s" % (k, v) + ("  # " + com.strip() if com.strip() else "")
    with open("config.txt", "w") as fh:
        fh.write("\n".join(lines))


class Web:
    def __init__(self, cfg, status):
        self.status = status            # dict, wird von main.py laufend aktualisiert
        self.nets = []                  # V6.5: bis zu 4 WLANs (wifi_ssid/_pass, wifi_ssid2/_pass2 ...)
        for n in ("", "2", "3", "4"):
            ss = str(cfg.get("wifi_ssid" + n, "")).strip()
            if ss:
                self.nets.append((ss, str(cfg.get("wifi_pass" + n, "")).strip()))
        self.ssid, self.ni = "", 0
        self.ok, self.ip, self.srv, self.reboot = False, "", None, 0
        self.url = str(cfg.get("update_url", "")).strip()
        if self.url and not self.url.endswith("/"):
            self.url += "/"
        self.auto = int(cfg.get("update_auto", 1))
        self.every = max(0.5, float(cfg.get("update_check_hours", 6))) * 3600000
        self.chk_at = 0                 # wann pruefen (ticks), 0 = sobald verbunden
        self.man = None                 # gefundenes neueres Update (version.json)
        self.want = False               # Installation angefordert (Webseite oder automatisch)
        self.force = False              # von der Webseite: auch waehrend des Heizens (Heizung wird ausgeschaltet)
        status["update"] = "off" if not self.url else "not checked"
        try:
            network.hostname("thermogrip")
        except Exception:
            pass
        self.w = network.WLAN(network.STA_IF)
        self.w.active(True)
        try:
            self.w.config(pm=0xa11140)  # Stromsparen aus -> Seite reagiert schnell
        except Exception:
            pass
        self._connect()

    def _connect(self):
        self.t = time.ticks_ms()
        if not self.nets:
            return
        pick = None
        try:
            self.w.disconnect()         # V6.7: alten Verbindungsversuch sauber beenden
        except Exception:
            pass
        if len(self.nets) == 1:         # V6.7: nur ein WLAN -> ohne Suche direkt verbinden (wie bis V6.4)
            pick = self.nets[0]
        else:
          try:                          # bekanntes WLAN mit dem besten Empfang suchen
              seen = {}
              for r in self.w.scan():
                  n = r[0].decode() if isinstance(r[0], bytes) else r[0]
                  seen[n] = max(seen.get(n, -999), r[3])
              best = -999
              for ss, pw in self.nets:
                  if ss in seen and seen[ss] > best:
                      best, pick = seen[ss], (ss, pw)
          except Exception:
              pass
        if pick is None:                # nichts gesehen -> der Reihe nach probieren
            pick = self.nets[self.ni % len(self.nets)]
            self.ni += 1
        self.ssid = pick[0]
        try:
            self.w.connect(pick[0], pick[1])
        except Exception:
            pass

    def text(self):
        if self.ok:
            return self.ip
        if not self.nets:
            return "no WiFi set"
        return ("connecting " if time.ticks_diff(time.ticks_ms(), self.t) < 20000 else "not found ") + self.ssid

    def poll(self, feed=None, busy=False):
        if self.reboot and time.ticks_diff(time.ticks_ms(), self.reboot) > 0:
            import machine
            machine.reset()
        if not self.ok:
            if self.w.isconnected():
                self.ip = self.w.ifconfig()[0]
                s = socket.socket()
                s.setsockopt(socket.SOL_SOCKET, socket.SO_REUSEADDR, 1)
                s.bind(("0.0.0.0", 80))
                s.listen(2)
                s.setblocking(False)
                self.srv, self.ok = s, True
                self.status["wifi"] = self.ssid
                if self.url and not self.chk_at:
                    self.chk_at = time.ticks_add(time.ticks_ms(), 5000)
            elif time.ticks_diff(time.ticks_ms(), self.t) > 30000:
                self._connect()                     # alle 30 s neu versuchen
            return
        if not self.w.isconnected():
            try:
                self.srv.close()
            except Exception:
                pass
            self.ok, self.srv = False, None
            self._connect()
            return
        if self.url and self.chk_at and not busy and time.ticks_diff(time.ticks_ms(), self.chk_at) > 0:
            self.check()
        try:
            c, _ = self.srv.accept()
        except OSError:
            return
        try:
            c.settimeout(5)
            self._handle(c, feed)
        except Exception as e:
            try:
                self._send(c, "500 Error", "text/plain", str(e))
            except Exception:
                pass
        finally:
            c.close()
            gc.collect()

    # ------------------------------------------------------------------ HTTP
    def _send(self, c, code, ctype, body):
        if isinstance(body, str):
            body = body.encode()
        c.send(("HTTP/1.0 %s\r\nContent-Type: %s\r\nContent-Length: %d\r\nCache-Control: no-store\r\nConnection: close\r\n\r\n"
                % (code, ctype, len(body))).encode())
        c.send(body)

    def _handle(self, c, feed):
        req = c.readline().decode().split()
        if len(req) < 2:
            return
        meth, path = req[0], req[1]
        clen = 0
        while True:
            h = c.readline()
            if not h or h == b"\r\n":
                break
            if h.lower().startswith(b"content-length:"):
                clen = int(h.split(b":")[1])
        q = ""
        if "?" in path:
            path, q = path.split("?", 1)

        if meth == "GET" and path == "/":
            c.send(b"HTTP/1.0 200 OK\r\nContent-Type: text/html; charset=utf-8\r\nCache-Control: no-store\r\nConnection: close\r\n\r\n")
            with open("web.html", "rb") as fh:
                while True:
                    b = fh.read(1024)
                    if not b:
                        break
                    c.send(b)
        elif meth == "GET" and path == "/api/status":
            self._send(c, "200 OK", "application/json", json.dumps(self.status))
        elif meth == "GET" and path == "/api/config":
            self._send(c, "200 OK", "application/json", json.dumps(_cfg_lines()))
        elif meth == "POST" and path == "/api/config":
            data = json.loads(c.read(clen)) if clen else {}
            _cfg_write(data)
            self._send(c, "200 OK", "application/json", '{"ok":true}')
        elif meth == "POST" and path == "/upload":
            name = q.replace("name=", "").strip()
            if name not in ALLOWED or clen <= 0:
                self._send(c, "400 Bad Request", "text/plain", "bad file name")
                return
            tmp = name + ".tmp"
            got = 0
            with open(tmp, "wb") as fh:
                while got < clen:
                    b = c.recv(min(1024, clen - got))
                    if not b:
                        break
                    fh.write(b)
                    got += len(b)
                    if feed:
                        feed()
            if got != clen:
                os.remove(tmp)
                self._send(c, "400 Bad Request", "text/plain", "incomplete %d/%d" % (got, clen))
                return
            try:
                os.remove(name)
            except OSError:
                pass
            os.rename(tmp, name)
            self._send(c, "200 OK", "application/json", '{"ok":true,"bytes":%d}' % got)
        elif meth == "POST" and path == "/api/update/check":
            self.check()
            self._send(c, "200 OK", "application/json", json.dumps({"update": self.status.get("update", "")}))
        elif meth == "POST" and path == "/api/update/install":
            if self.man:
                self.want = self.force = True
            self._send(c, "200 OK", "application/json", json.dumps({"ok": bool(self.man)}))
        elif meth == "POST" and path == "/api/restart":
            self._send(c, "200 OK", "application/json", '{"ok":true}')
            self.reboot = time.ticks_add(time.ticks_ms(), 500)
        else:
            self._send(c, "404 Not Found", "text/plain", "not found")

    # ------------------------------------------------------------------ Update aus dem Internet / vom PC (V6.5)
    def _get(self, url):
        proto, _, host, path = url.split("/", 3)
        port = 443 if proto == "https:" else 80
        if ":" in host:
            host, port = host.split(":")[0], int(host.split(":")[1])
        ai = socket.getaddrinfo(host, port, 0, socket.SOCK_STREAM)[0][-1]
        s = socket.socket()
        s.settimeout(5)
        s.connect(ai)
        if proto == "https:":
            import ssl
            try:
                ctx = ssl.SSLContext(ssl.PROTOCOL_TLS_CLIENT)
                ctx.verify_mode = ssl.CERT_NONE
                s = ctx.wrap_socket(s, server_hostname=host)
            except AttributeError:
                s = ssl.wrap_socket(s, server_hostname=host)
        s.write(("GET /%s HTTP/1.0\r\nHost: %s\r\nUser-Agent: thermogrip\r\nConnection: close\r\n\r\n" % (path, host)).encode())
        def line():
            b = b""
            while not b.endswith(b"\n"):
                ch = s.read(1)
                if not ch:
                    break
                b += ch
            return b
        code = int(line().split()[1])
        clen = -1
        while True:
            h = line()
            if not h or h in (b"\r\n", b"\n"):
                break
            if h.lower().startswith(b"content-length:"):
                clen = int(h.split(b":")[1])
        if code != 200:
            s.close()
            raise OSError("HTTP %d" % code)
        return s, clen

    @staticmethod
    def _vt(v):
        out = []
        for p in str(v).strip().lstrip("Vv").split("."):
            try:
                out.append(int(p))
            except ValueError:
                out.append(0)
        return tuple(out)

    def check(self):
        self.chk_at = time.ticks_add(time.ticks_ms(), int(self.every))
        if not self.url or not self.ok:
            return
        try:
            s, n = self._get(self.url + "version.json?t=%d" % time.ticks_ms())
            raw = b""
            while True:
                b = s.read(512)
                if not b:
                    break
                raw += b
            s.close()
            man = json.loads(raw)
            if self._vt(man["version"]) > self._vt(self.status.get("version", "V0")):
                self.man = man
                self.status["update"] = man["version"] + " available"
                if self.auto:
                    self.want = True
            else:
                self.man = None
                self.status["update"] = "up to date (" + str(man["version"]) + ")"
        except Exception as e:
            self.status["update"] = "check failed: " + str(e)
        gc.collect()

    def install(self, progress, feed=None):
        """Laedt alle Dateien aus version.json, prueft Groesse + CRC, ersetzt sie und startet neu."""
        import binascii
        man, self.want = self.man, False
        files = [f for f in man["files"] if f["name"] in ALLOWED and f["name"] != "config.txt"]
        total = sum(f["size"] for f in files) or 1
        done, last = 0, -1
        try:
            for f in files:
                progress(done * 100 // total, f["name"])
                s, n = self._get(self.url + f["name"] + "?v=" + man["version"])
                crc, got = 0, 0
                with open(f["name"] + ".tmp", "wb") as fh:
                    while got < f["size"]:
                        b = s.read(min(1024, f["size"] - got))
                        if not b:
                            break
                        fh.write(b)
                        crc = binascii.crc32(b, crc)
                        got += len(b)
                        if feed:
                            feed()
                        pc = (done + got) * 100 // total
                        if pc != last:
                            last = pc
                            progress(pc, f["name"])
                s.close()
                if got != f["size"] or (crc & 0xFFFFFFFF) != f["crc"]:
                    raise OSError(f["name"] + " damaged")
                done += got
                gc.collect()
            for f in sorted(files, key=lambda f: f["name"] == "main.py"):   # main.py zuletzt
                try:
                    os.remove(f["name"])
                except OSError:
                    pass
                os.rename(f["name"] + ".tmp", f["name"])
            progress(100, "done - restarting")
            time.sleep_ms(800)
            import machine
            machine.reset()
        except Exception as e:
            for f in files:
                try:
                    os.remove(f["name"] + ".tmp")
                except OSError:
                    pass
            self.man = None
            self.status["update"] = "update failed: " + str(e)
            progress(-1, str(e))
