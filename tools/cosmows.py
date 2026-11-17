#!/usr/bin/env python3
"""Mini-WebSocket-Client für den CosmoStreamer (Port 8081): sendet JSON-Befehle, gibt Text-Antworten aus (Passwörter maskiert)."""
import socket, base64, os, struct, sys, json, time, re
host = sys.argv[1]; cmds = sys.argv[2:]; wait = 25
s = socket.create_connection((host, 8081), timeout=5)
key = base64.b64encode(os.urandom(16)).decode()
s.send(("GET / HTTP/1.1\r\nHost: %s:8081\r\nUpgrade: websocket\r\nConnection: Upgrade\r\nSec-WebSocket-Key: %s\r\nSec-WebSocket-Version: 13\r\nOrigin: http://%s\r\n\r\n" % (host, key, host)).encode())
h = b""
while b"\r\n\r\n" not in h: h += s.recv(1)
print(h.split(b"\r\n")[0].decode())
def send(t):
    d = t.encode(); m = os.urandom(4)
    hdr = bytes([0x81]) + (bytes([0x80 | len(d)]) if len(d) < 126 else bytes([0x80 | 126]) + struct.pack(">H", len(d)))
    s.send(hdr + m + bytes(b ^ m[i % 4] for i, b in enumerate(d)))
def rx(n):
    b = b""
    while len(b) < n:
        c = s.recv(n - len(b))
        if not c: raise EOFError
        b += c
    return b
def frame():
    a, b = rx(2); op = a & 15; ln = b & 127
    if ln == 126: ln = struct.unpack(">H", rx(2))[0]
    elif ln == 127: ln = struct.unpack(">Q", rx(8))[0]
    if b & 128: rx(4)
    return op, rx(ln)
time.sleep(1)
for c in cmds: send(c); time.sleep(0.5)
seen = {}
end = time.time() + wait; s.settimeout(2)
while time.time() < end:
    try: op, d = frame()
    except socket.timeout: continue
    except EOFError: break
    i = d.find(b"{")
    if b"cmd" in d and i >= 0:
        t = d[i:].decode("utf-8", "replace")
        if True:
            t = re.sub(r'("(?:\w*_psk|\w*pass\w*)"\s*:\s*")[^"]*"', r'\1***"', t)
            print(t[:3000])
