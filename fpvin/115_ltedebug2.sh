#timeout 60
cd /opt/fpv && python3 - <<'PY'
import lteinfo as L, urllib.request
orig = L._get
def spy(host, path, auth=None, timeout=3):
    st, hdr, body = orig(host, path, auth, timeout)
    if path.startswith("/login.cgi?"):
        print("login answer:", st, repr(body[:200]), {k: v for k, v in hdr.items() if k.lower() in ("set-cookie", "www-authenticate", "content-length")})
    return st, hdr, body
L._get = spy
h = L.stick_host(); u, p = L.load_login()
L.login(h, u, p)
ls, vals = L.get_file(h, u, p, "status1"); print("status1:", ls, len(vals))
PY
echo "[100%] done"
