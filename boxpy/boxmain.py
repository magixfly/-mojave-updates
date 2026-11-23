"""Core Tracker on the Carlin box (Android) - starts bodenstation/server.py without a Raspberry Pi.

Python here is a musl build started through the musl loader (see run.sh). Android has no
/etc/resolv.conf, so musl cannot resolve host names by itself: this file adds a small DNS
fallback (UDP to the Wi-Fi router / public DNS) before server.py is loaded.
"""
import os, sys, socket, struct, random, subprocess, runpy

HERE = os.path.dirname(os.path.abspath(__file__))
os.environ["CT_BOX"] = "1"

_orig = socket.getaddrinfo
_cache = {}


def _servers():
    s = []
    for p in ("net.dns1", "net.dns2"):
        try:
            v = subprocess.run(["getprop", p], capture_output=True, text=True, timeout=3).stdout.strip()
            if v:
                s.append(v)
        except Exception:
            pass
    try:   # Android keeps the default route in a per-network table, "ip route get" finds the router
        out = subprocess.run(["ip", "route", "get", "8.8.8.8"], capture_output=True, text=True, timeout=3).stdout.split()
        if "via" in out:
            s.append(out[out.index("via") + 1])
    except Exception:
        pass
    return s + ["1.1.1.1", "8.8.8.8"]


def _query(name, server):
    tid = random.randint(0, 65535)
    q = struct.pack(">HHHHHH", tid, 0x0100, 1, 0, 0, 0)
    for part in name.rstrip(".").split("."):
        q += bytes([len(part)]) + part.encode()
    q += b"\0" + struct.pack(">HH", 1, 1)
    so = _orig_socket(socket.AF_INET, socket.SOCK_DGRAM)
    so.settimeout(2.5)
    try:
        so.sendto(q, (server, 53))
        r = so.recv(2048)
    finally:
        so.close()
    if struct.unpack(">H", r[:2])[0] != tid:
        return []
    an = struct.unpack(">H", r[6:8])[0]
    i = len(q)
    ips = []
    for _ in range(an):
        if r[i] & 0xC0 == 0xC0:
            i += 2
        else:
            while r[i]:
                i += r[i] + 1
            i += 1
        t, _c, _ttl, ln = struct.unpack(">HHIH", r[i:i + 10])
        i += 10
        if t == 1 and ln == 4:
            ips.append(socket.inet_ntoa(r[i:i + 4]))
        i += ln
    return ips


_orig_socket = socket.socket


def _resolve(host):
    if host in _cache:
        return _cache[host]
    for srv in _servers():
        try:
            ips = _query(host, srv)
            if ips:
                _cache[host] = ips
                return ips
        except Exception:
            continue
    return []


def getaddrinfo(host, port, family=0, type=0, proto=0, flags=0):
    try:
        return _orig(host, port, family, type, proto, flags)
    except socket.gaierror:
        if not host or family == socket.AF_INET6:
            raise
        h = host.decode() if isinstance(host, bytes) else host
        ips = _resolve(h)
        if not ips:
            raise
        out = []
        for ip in ips:
            out += _orig(ip, port, socket.AF_INET, type, proto, flags)
        return out


socket.getaddrinfo = getaddrinfo

if not os.environ.get("SSL_CERT_FILE") and os.path.exists(os.path.join(HERE, "ca.pem")):
    os.environ["SSL_CERT_FILE"] = os.path.join(HERE, "ca.pem")

srv = os.path.join(HERE, "bodenstation", "server.py")
sys.path.insert(0, os.path.dirname(srv))
sys.argv = [srv]
runpy.run_path(srv, run_name="__main__")
