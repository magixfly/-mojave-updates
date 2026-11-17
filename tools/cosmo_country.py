#!/usr/bin/env python3
"""CosmoStreamer: WLAN-Land (System country) setzen, alle anderen WLAN-Werte (auch Passwörter) unverändert übernehmen."""
import sys, json, time, importlib.util
spec = importlib.util.spec_from_file_location("x", "/dev/null")
host, country = sys.argv[1], sys.argv[2]
import socket, base64, os, struct
def conn():
    s = socket.create_connection((host, 8081), timeout=5)
    k = base64.b64encode(os.urandom(16)).decode()
    s.send(("GET / HTTP/1.1\r\nHost: %s:8081\r\nUpgrade: websocket\r\nConnection: Upgrade\r\nSec-WebSocket-Key: %s\r\nSec-WebSocket-Version: 13\r\nOrigin: http://%s\r\n\r\n" % (host, k, host)).encode())
    h = b""
    while b"\r\n\r\n" not in h: h += s.recv(1)
    return s
def send(s, t):
    d = t.encode(); m = os.urandom(4)
    hdr = bytes([0x81]) + (bytes([0x80 | len(d)]) if len(d) < 126 else bytes([0xFE]) + struct.pack(">H", len(d)))
    s.send(hdr + m + bytes(b ^ m[i % 4] for i, b in enumerate(d)))
def rx(s, n):
    b = b""
    while len(b) < n:
        c = s.recv(n - len(b))
        if not c: raise EOFError
        b += c
    return b
def get(s, want, secs=15):
    end = time.time() + secs; s.settimeout(2)
    while time.time() < end:
        try:
            a, b = rx(s, 2); ln = b & 127
            if ln == 126: ln = struct.unpack(">H", rx(s, 2))[0]
            elif ln == 127: ln = struct.unpack(">Q", rx(s, 8))[0]
            d = rx(s, ln); i = d.find(b"{")
            if i >= 0 and want.encode() in d:
                return json.loads(d[i:].decode("utf-8", "replace"))
        except socket.timeout: pass
    return None
s = conn(); time.sleep(1)
send(s, '{"cmd":"config_request","param":"wifi"}')
c = get(s, "config_answer")
if not c: print("keine Antwort"); sys.exit(1)
print("vorher: Land", repr(c.get("sys_country")), "WLAN", c.get("wifi_iface"), c.get("wifi_ssid"), "IP", repr(c.get("wifi_ip")))
v = {"cmd": "updateconfig", "param": "wlan",
     "value": c.get("camera_iface", ""), "value2": c.get("camera_ssid", ""), "value3": c.get("camera_psk", ""),
     "value4": c.get("wifi_iface", ""), "value5": c.get("wifi_ssid", ""), "value6": c.get("wifi_psk", ""),
     "value7": c.get("ap_iface", ""), "value8": c.get("ap_ssid", ""), "value9": c.get("ap_psk", ""),
     "value10": str(c.get("ap_mode", 2)), "value11": "" if not c.get("ap_channel") else str(c.get("ap_channel")),
     "value12": "" if c.get("ap_country") in (None, "null") else c.get("ap_country"),
     "value13": country, "value14": str(c.get("wifi_s_enabled", 0)), "value15": c.get("wifi_s_addr", ""),
     "value16": c.get("wifi_s_mask", ""), "value17": c.get("wifi_s_gw", ""), "value18": c.get("wifi_s_dns", "")}
send(s, json.dumps(v, ensure_ascii=False, separators=(",", ":")))
print("gespeichert: Land", country)
s.close()
for i in range(8):
    time.sleep(15)
    try:
        s = conn(); time.sleep(1); send(s, '{"cmd":"config_request","param":"wifi"}'); c = get(s, "config_answer"); s.close()
        if c: print("nach %d s: Land %r, WLAN-IP %r" % ((i + 1) * 15, c.get("sys_country"), c.get("wifi_ip")))
        if c and c.get("wifi_ip"): break
    except Exception as e: print("nach %d s: %s" % ((i + 1) * 15, e))
