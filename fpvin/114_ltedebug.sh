#timeout 60
cd /opt/fpv && python3 - <<'PY'
import lteinfo as L
h = L.stick_host(); print("host", h)
st, hdr, body = L._get(h, "/login.cgi"); print("challenge", st, (hdr.get("WWW-Authenticate") or "")[:80])
u, p = L.load_login(); print("user length", len(u), "pass length", len(p), "special chars in pass:", any(not c.isalnum() for c in p))
ok = L.login(h, u, p); print("login http ok:", ok)
for f in ("status1",):
    ls, vals = L.get_file(h, u, p, f); print(f, "login_status:", repr(ls), "values:", len(vals), "rssi", vals.get("rssi"))
st, hdr, body = L._get(h, "/xml_action.cgi?method=get&module=duster&file=status1"); print("without auth:", st, body[:120])
PY
echo "[100%] done"
