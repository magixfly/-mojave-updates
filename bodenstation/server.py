#!/usr/bin/env python3
# Mojave Ground Station (Bodenstation) for Raspberry Pi 4
# Reads CRSF telemetry over USB serial (MT12 telemetry mirror or ESP32 receiver),
# serves the full-screen map page and an offline tile cache.
# Only Python 3 standard library needed.

import subprocess
import os, sys, json, time, math, threading, struct, glob, select, shutil, queue, random
import urllib.request, bisect, re, socket
from http.server import ThreadingHTTPServer, BaseHTTPRequestHandler
from urllib.parse import urlparse, parse_qs

VERSION = "2.0.31"
BASE = os.path.dirname(os.path.abspath(__file__))
WIN = os.name == "nt"                 # V2.0.27: also runs on Windows 10/11 (ESP32 receiver on a COM port)
CFG_FILE = os.path.join(BASE, "config.txt")

# ---------------------------------------------------------------- config.txt
DEFAULTS = [
    ("port", "8080", "Web port of the ground station page"),
    ("serial", "auto", "auto = first /dev/ttyACM* or /dev/ttyUSB*, then /dev/serial0 (ESP on the GPIO UART), or e.g. /dev/ttyACM0"),
    ("baud", "115200", "Serial speed (USB from MT12/ESP32 ignores it)"),
    ("test", "0", "1 = start with simulated test ride"),
    ("test_ride", "demo_ride.csv", "Demo ride played in test mode (empty or missing = circle around test_lat/test_lon)"),
    ("test_lat", "48.2268", "Centre of the test ride"),
    ("test_lon", "15.6485", ""),
    ("tiles_dir", "tiles", "Tile folder (ki = AI tiles first, then ortho)"),
    ("online", "1", "1 = load missing tiles from the internet and keep them"),
    ("online_url", "https://maps.wien.gv.at/basemap/bmaporthofoto30cm/normal/google3857/{z}/{y}/{x}.jpeg", "Aerial photo basemap.at"),
    ("online_url2", "https://server.arcgisonline.com/ArcGIS/rest/services/World_Imagery/MapServer/tile/{z}/{y}/{x}", "Fallback Esri"),
    ("online_timeout_s", "10", "Seconds to wait for one internet tile"),
    ("ipv4_only", "1", "1 = download tiles only via IPv4 (faster in WLAN/hotspot)"),
    ("online_max_zoom", "19", "Highest zoom loaded from the internet"),
    ("max_zoom", "21", "Highest zoom on screen (20/21 = AI tiles or enlarged)"),
    ("still_kmh", "2", "Below this speed the car counts as standing: map/arrow do not move"),
    ("still_jump_m", "15", "...unless the position jumps more than this (car carried away)"),
    ("freeze_disarmed", "1", "1 = also stand still while the car is disarmed (mode OK/WAIT/...*)"),
    ("auto_zoom", "1", "1 = zoom out a little when driving fast (like a car navi), back in when standing"),
    ("auto_zoom_out", "0.7", "Zoom levels out at auto_zoom_kmh"),
    ("auto_zoom_kmh", "70", "Speed for the full zoom out"),
    ("usb_import", "1", "1 = copy tiles from a USB stick to the SD card automatically (only missing ones)"),
    ("usb_dir", "/media/user1", "Where USB sticks are mounted"),
    ("batt_mah", "6000", "Capacity of the car battery in mAh for x % left (0 = off; taken from the Core)"),
    ("range_warn_m", "0", "Warn when the car is farther from home than this (m, 0 = off)"),
    ("sound", "1", "1 = warning beeps (3.5 mm jack / HDMI)"),
    ("core_live", "1", "1 = read temperatures and battery % from the Core over WLAN when reachable"),
    ("core_radio", "1", "1 = use the Core radio broadcast (ESP-NOW, Core V2.72+) heard by the ESP receiver - works without WLAN"),
    ("core_show", "1", "1 = show the Core line on the map (menu Core info)"),
    ("night", "0", "1 = night mode (darker map, menu)"),
    ("me_gps", "1", "1 = use the GPS module on the ESP receiver as own position (pilot / ground station)"),
    ("me_timeout_s", "5", "Own GPS older than this = not shown"),
    ("bright", "100", "Display brightness in % (set with the menu)"),
    ("car_size", "1.0", "Size of the car arrow on the map (1.5 = old size)"),
    ("wifi_dev", "wlan0", "WLAN device for the quality display"),
    ("start_zoom", "17", ""),
    ("orientation", "north", "north = north up, heading = driving direction up"),
    ("cells", "auto", "auto = below 16.9 V 4S, above 6S; or a number"),
    ("cell_pre", "3.65", "Pre-warning (orange) below this cell voltage"),
    ("cell_warn", "3.50", "Warning (red) below this cell voltage"),
    ("cell_warn_s", "3", "... for at least this many seconds"),
    ("lq_warn", "50", "Warning below this link quality in % (0 = off)"),
    ("core_sync", "1", "1 = take warning limits from the Core (/api/cfg) when reachable, saved here"),
    ("core_hosts", "192.168.178.213 mojave.local", "Core addresses, separated by spaces"),
    ("home_min_sats", "6", "Home point is set at first fix with this many satellites"),
    ("link_timeout_s", "2", "No data for this long = link lost"),
    ("preload_radius_m", "1000", "Default radius for map preload"),
    ("preload_zmin", "12", ""),
    ("preload_zmax", "19", ""),
    ("log", "1", "1 = write every ride as CSV into logs/"),
    ("vgps", "1", "1 = test GPS (VGPS) at home: fixed position when the real GPS has no fix (like the Core)"),
    ("vgps_lat", "48.1872125", "VGPS position (Core: 5JP7+VGQ St. Poelten)"),
    ("vgps_lon", "15.6138594", ""),
    ("vgps_sats", "12", "Satellites shown for VGPS"),
    ("vgps_ssid", "Optimus Prime", "VGPS only in this WLAN (empty = always when no fix)"),
    ("names", "Thorsten,Mario", "Driver names of car 1 and car 2 (tap the name in the tracker to change), saved with each ride"),
    ("ride_min_m", "100", "Ride list: a ride/flight counts from this distance in metres ..."),
    ("ride_min_kmh", "20", "... AND this top speed in km/h (standing at home is not listed)"),
    ("ride_min_s", "60", "V2.0.12: ... AND it lasted at least this many seconds"),
    ("gap_s", "15", "V2.0.15: track/replay: no position for this many seconds -> gap instead of a straight line"),
    ("ride_gap_s", "10", "V2.0.11: no telemetry for this many seconds -> the ride/flight is finished, the next data start a new one"),
    ("map_names", "1", "1 = show the driver names next to the cars on the map (menu)"),
    ("icons", "", "Map symbol per car (long tap): date|1:0,2:1 (0 arrow, 1 car, 2 plane), only valid on that day"),
    ("senders", "", "Known senders (menu Sender): MAC/slot/type/symbol/colour/name/pilot;... slot 1 = prefers the main view, 2 = shown, 0 = hidden; type car/plane; symbol 0 arrow 1 car 2 plane; name = model, pilot = driver/pilot"),
    ("sender_auto", "1", "1 = a new sender (ESP firmware 1.3+) is shown automatically (0 = only senders set up in the menu)"),
    ("log_stop_s", "3", "V2.0.11: after DISARM the log keeps running this many seconds; armed again within this time = same ride, later = the ride/flight is finished"),
    ("log_disarmed", "0", "V2.0.8: 0 = arming starts a new ride/flight and nothing is logged while DISARMED (flight controller); 1 = log always"),
    ("trail_m", "100", "V2.0.7: live tracks: the newest metres fully visible, then fading out over the same distance (0 = whole track)"),
    ("max_vehicles", "6", "V2.0.6: how many vehicles (senders) are shown at the same time (2..6)"),
    ("veh_timeout_s", "300", "V2.0.6: a vehicle without telemetry for this long frees its place (its last position stays until another one takes it)"),
    ("lang", "en", "Language of the screen: en = English, de = Deutsch (menu: Language)"),
    ("launcher_s", "10", "Start menu after power on: seconds until the tracker starts by itself (0 = no start menu)"),
    ("ui_scale", "0", "0 = fit screen automatically (layout for 1280x720), or e.g. 1.2 = bigger"),
]

def load_cfg():
    cfg = {k: v for k, v, _ in DEFAULTS}
    if os.path.exists(CFG_FILE):
        seen = set()
        for line in open(CFG_FILE, encoding="utf-8", errors="ignore"):
            line = line.split("#", 1)[0].strip()
            if "=" in line:
                k, v = line.split("=", 1)
                cfg[k.strip()] = v.strip()
                seen.add(k.strip())
        if any(k not in seen for k, _, _ in DEFAULTS):
            save_cfg(cfg)   # add new settings to config.txt, keep the old values
    else:
        save_cfg(cfg)
    return cfg

def save_cfg(cfg):
    with open(CFG_FILE, "w", encoding="utf-8") as f:
        f.write(f"# Mojave Ground Station V{VERSION} - settings (read at start)\n")
        for k, _, c in DEFAULTS:
            f.write(f"{k}={cfg.get(k, '')}" + (f"   # {c}" if c else "") + "\n")

CFG = load_cfg()
def ci(k): return int(float(CFG[k]))
def cf(k): return float(CFG[k])

TILES = os.path.join(BASE, CFG["tiles_dir"]) if not os.path.isabs(CFG["tiles_dir"]) else CFG["tiles_dir"]
os.makedirs(os.path.join(TILES, "ortho"), exist_ok=True)
os.makedirs(os.path.join(TILES, "ki"), exist_ok=True)

# ---------------------------------------------------------------- state
LOCK = threading.Lock()
S = {
    "ver": VERSION, "src": "-", "dev": "", "age": 99.0,
    "lat": None, "lon": None, "spd": 0.0, "hdg": 0.0, "alt": 0, "sats": 0,
    "v": 0.0, "cells": 0, "cell": 0.0, "cur": 0.0, "mah": 0, "pct": None,
    "lq": None, "rssi": None, "snr": None, "rfmode": None, "txpw": None,
    "roll": 0.0, "pitch": 0.0, "mode": "",
    "home": None, "dist": None, "maxspd": 0.0, "trip": 0.0, "warn": "", "vgps": False,
}
TRACK = []          # [lat, lon, spd]
LAST_RX = 0.0
LOW_SINCE = None
PRE_SINCE = None
CORE = {"ok": 0}
TEST = {"on": CFG["test"] == "1", "cars": 1}
C2 = {}             # V1.9: second car (2-car demo)
TRACK2 = []
LOG = {"f": None}
LOG2 = {"f": None, "mac": None}   # V2.0.5: own ride log for car 2 (second sender, e.g. plane)

def haversine(a, b, c, d):
    R = 6371000.0
    p1, p2 = math.radians(a), math.radians(c)
    dp, dl = p2 - p1, math.radians(d - b)
    h = math.sin(dp / 2) ** 2 + math.cos(p1) * math.cos(p2) * math.sin(dl / 2) ** 2
    return 2 * R * math.asin(min(1, math.sqrt(h)))

def cell_count(v):
    if CFG["cells"] != "auto":
        return max(1, int(CFG["cells"]))
    if v < 5:
        return 0
    return 4 if v < 16.9 else 6

def got_data(src):
    global LAST_RX
    LAST_RX = time.time()
    S["src"] = src

HOME_WIFI = {"ok": False}

# Core config keys -> our config keys (limits set by Thorsten in the Core)
CORE_MAP = {"zelleWarnV": "cell_warn", "zelleVorV": "cell_pre", "zelleWarnSek": "cell_warn_s", "lqWarnPct": "lq_warn", "akkuKapMah": "batt_mah"}

# ---------------------------------------------------------------- V2.0.22: devices in the network (menu DEVICES)
DEVS = {"t": 0.0, "busy": False, "prog": 0, "d": None}

def _dev_ip(h):
    """host name (also .local over mDNS) -> IPv4, or None"""
    try:
        return socket.getaddrinfo(h, 80, socket.AF_INET)[0][4][0]
    except Exception:
        return None

def _dev_get(h, path, t=2.5):
    try:
        with urllib.request.urlopen("http://%s%s" % (h, path), timeout=t) as r:
            return json.loads(r.read().decode("utf-8", "ignore"))
    except Exception:
        return None

def devices_scan():
    DEVS["busy"], DEVS["prog"] = True, 5
    out = {}
    try:
        ips = []
        try:
            for l in subprocess.run(["ip", "-4", "-o", "addr", "show"], capture_output=True, text=True, timeout=3).stdout.splitlines():
                f = l.split()
                if len(f) > 3 and f[1] != "lo":
                    ips.append([f[1], f[3].split("/")[0]])
        except Exception:
            pass
        ssid = ""
        try:
            ssid = subprocess.run(["iwgetid", "-r"], capture_output=True, text=True, timeout=3).stdout.strip()
        except Exception:
            pass
        hn = socket.gethostname()
        if not ips:
            try:
                s0 = socket.socket(socket.AF_INET, socket.SOCK_DGRAM); s0.connect(("8.8.8.8", 80)); ips.append(["net", s0.getsockname()[0]]); s0.close()
            except Exception:
                pass
        out["tracker"] = {"ok": True, "host": hn + ".local", "ips": ips, "ssid": ssid, "ver": VERSION}
        DEVS["prog"] = 20
        # Core: addresses from config.txt (core_hosts), the one that answered last first
        hs = []
        for h in [CORE.get("host")] + CFG.get("core_hosts", "").split() + ["mojave.local"]:
            if h and h not in hs:
                hs.append(h)
        core = {"ok": False, "host": "mojave.local", "ip": _dev_ip("mojave.local")}
        for i, h in enumerate(hs):
            st = _dev_get(h, "/api/status")
            DEVS["prog"] = 20 + int(35 * (i + 1) / len(hs))
            if st:
                core = {"ok": True, "host": h if not re.match(r"^[0-9.]+$", h) else "mojave.local", "ip": st.get("ip") or _dev_ip(h) or h,
                        "ssid": st.get("wlSsid") or "", "rssi": st.get("wlRssi")}
                sy = _dev_get(h, "/api/sys")
                if sy:
                    core["ver"] = sy.get("fw")
                break
        out["core"] = core
        DEVS["prog"] = 60
        navi = {"ok": False, "host": "mojave-navi.local", "ip": None}
        for i, h in enumerate(["mojave-navi.local", "navi.local"]):
            ip = _dev_ip(h)
            DEVS["prog"] = 60 + 20 * (i + 1)
            if not ip:
                continue
            st = _dev_get(ip, "/api/status")
            navi = {"ok": bool(st), "host": h, "ip": (st or {}).get("ip") or ip}
            if st:
                navi.update(ver=st.get("ver"), ssid=st.get("ssid") or "", rssi=st.get("rssi"))
                break
        out["navi"] = navi
    finally:
        DEVS["d"], DEVS["t"], DEVS["busy"], DEVS["prog"] = out, time.time(), False, 100

def core_thread():
    # every 60 s: read /api/cfg from the Core; changed limits are written into config.txt
    while True:
        if CFG.get("core_sync", "1") == "1":
            for h in CFG.get("core_hosts", "").split():
                try:
                    with urllib.request.urlopen("http://%s/api/cfg" % h, timeout=3) as r:
                        c = json.loads(r.read().decode("utf-8", "ignore"))
                except Exception:
                    continue
                changed = False
                for ck, k in CORE_MAP.items():
                    if ck in c:
                        v = str(c[ck])
                        if CFG.get(k) != v:
                            CFG[k] = v
                            changed = True
                if changed:
                    save_cfg(CFG)
                CORE["ok"] = time.time()
                CORE["host"] = h
                break
        time.sleep(60)

CORE_LIVE = {"d": None, "t": 0.0}
CORE_RADIO = {"t": 0.0}
ME = {"t": 0.0}     # own position from the GPS module on the ESP receiver (V1.8)

# ---------------------------------------------------------------- V2.0: senders (radios/models) -> car slots
# ESP firmware 1.3 sends a CRSF frame 0x7D (MAC of the sender + dBm) right before each telemetry frame.
SEEN = {}           # mac -> {"rssi", "t", "n", "pps", "c"} heard senders
SND_COLS = ["1a8cff", "d4ff00", "ff3b30", "ff9500", "bf5af2", "00e5ff", "ffffff", "ff2d95"]

def parse_senders(v):
    out = {}
    for it in (v or "").split(";"):
        f = it.strip().split("/")
        if len(f) < 6 or not re.fullmatch(r"[0-9A-F]{2}(:[0-9A-F]{2}){5}", f[0].upper()):
            continue
        try:
            out[f[0].upper()] = {"slot": max(0, min(2, int(f[1]))), "type": "plane" if f[2] == "plane" else "car",
                                 "sym": max(0, min(2, int(f[3]))), "col": f[4].lower() if re.fullmatch(r"[0-9a-fA-F]{6}", f[4]) else "",
                                 "name": f[5].strip()[:14], "pilot": (f[6].strip()[:14] if len(f) > 6 else "")}   # V2.0.5: pilot
        except Exception:
            pass
    return out

def senders_str(d):
    return ";".join("%s/%d/%s/%d/%s/%s/%s" % (m, x["slot"], x["type"], x["sym"], x["col"], x["name"], x.get("pilot", "")) for m, x in d.items())

SND = parse_senders(CFG.get("senders", ""))

def save_senders():
    CFG["senders"] = senders_str(SND)
    save_cfg(CFG)

ACT = {}            # V2.0.6: slot -> {"mac", "t"} active senders (heard within veh_timeout_s)
SLOTMAC = {}        # slot -> mac of the sender that uses / used this slot (last position stays shown)
NEWN = {"n": 0}

def vmax():
    try:
        return max(2, min(6, ci("max_vehicles")))
    except Exception:
        return 6

def slot_cfg(n):
    """settings of the sender on slot n (1 = main vehicle), or None"""
    m = SLOTMAC.get(n)
    x = SND.get(m) if m else None
    if not x:
        return None
    r = dict(x); r["mac"] = m
    return r

def slot_reset(n, mac):
    """V2.0.6: a different sender takes slot n -> start this slot fresh (track, home, log file)"""
    global TRACK
    if n == 1:
        TRACK = []
        S.update(home=None, alt0=None, dist=None, maxspd=0.0, lat=None, lon=None, trip=0.0, parked=False)
        if LOG["f"]:
            try:
                LOG["f"].close()
            except Exception:
                pass
            LOG["f"] = None
    else:
        CX[n].clear(); TRK[n].clear(); CXRX[n]["t"] = 0.0
        if LOGX[n]["f"]:
            try:
                LOGX[n]["f"].close()
            except Exception:
                pass
            LOGX[n]["f"] = None
    SLOTMAC[n] = mac

def promote(n):
    """V2.0.8: move the vehicle of slot n (>= 2) to the main slot 1 - position, home, track and values go with it."""
    global TRACK, LAST_RX
    a = ACT.pop(n)
    c = dict(CX[n]); tr = list(TRK[n])
    if LOGX[n]["f"]:
        try:
            LOGX[n]["f"].close()
        except Exception:
            pass
        LOGX[n]["f"] = None
    CX[n].clear(); TRK[n].clear(); CXRX[n]["t"] = 0.0; SLOTMAC.pop(n, None)
    slot_reset(1, a["mac"])
    for k in ("lat", "lon", "spd", "hdg", "alt", "sats", "gts", "home", "dist", "maxspd", "trip", "alt0", "v", "cur", "mah",
              "cells", "cell", "lq", "rssi", "snr", "mode", "armed", "pitch", "roll"):
        if k in c:
            S[k] = c[k]
    TRACK = tr
    ACT[1] = a
    LAST_RX = time.time()
    print("promoted", a["mac"], "from slot", n, "to the main view")

def sender_heard(mac, rssi):
    """called for each 0x7D frame -> slot (1 = main vehicle, 2..6) or 0 = not shown.
    V2.0.6: slots are given to the ACTIVE senders - the first one gets the main view."""
    now = time.time()
    e = SEEN.get(mac)
    if e is None:
        e = SEEN[mac] = {"rssi": rssi, "t": now, "n": 0, "pps": 0, "c": 0, "t1": now}
    e["rssi"] = rssi if e["n"] == 0 else round(e["rssi"] * 0.8 + rssi * 0.2, 1)
    e["t"] = now; e["n"] += 1; e["c"] += 1
    if now - e["t1"] >= 1.0:
        e["pps"] = round(e["c"] / (now - e["t1"])); e["c"] = 0; e["t1"] = now
    x = SND.get(mac)
    if x is None:
        if CFG.get("sender_auto", "1") != "1":
            return 0
        used = {v["col"] for v in SND.values()}
        col = next((c for c in SND_COLS[2:] + SND_COLS[:2] if c not in used), SND_COLS[2])
        k = 2 + sum(1 for v in SND.values() if v["name"].startswith("PLANE"))
        SND[mac] = {"slot": 2, "type": "plane", "sym": 2, "col": col, "name": "PLANE %d" % k, "pilot": ""}
        print("new sender", mac)
        try:
            save_senders()
        except Exception:
            pass
        x = SND[mac]
    if x["slot"] == 0:                          # hidden in the menu
        return 0
    to = cf("veh_timeout_s")
    for n in [n for n, a in ACT.items() if now - a["t"] > to and a["mac"] != mac]:
        del ACT[n]
    for n, a in list(ACT.items()):
        if a["mac"] == mac:
            a["t"] = now
            if n >= 2 and 1 not in ACT and n == min(ACT):
                promote(n)                       # V2.0.8: main vehicle gone -> this one becomes the main view
                return 1
            return n
    free = [n for n in range(1, vmax() + 1) if n not in ACT]
    if not free:
        return 0
    n = 1 if 1 in free else (2 if x["slot"] == 2 and 2 in free else free[0])
    ACT[n] = {"mac": mac, "t": now}
    if SLOTMAC.get(n) != mac:
        slot_reset(n, mac)
    if n == 1:
        log_names()
    return n

def senders_list():
    now = time.time()
    macs = list(SND.keys()) + [m for m in SEEN if m not in SND]
    out = []
    for m in macs:
        e, x = SEEN.get(m), SND.get(m)
        act = next((n for n, a in ACT.items() if a["mac"] == m), 0)
        out.append({"mac": m, "known": x is not None, "slot": x["slot"] if x else 0, "act": act, "type": x["type"] if x else "car",
                    "sym": x["sym"] if x else 0, "col": x["col"] if x else "", "name": x["name"] if x else "", "pilot": x.get("pilot", "") if x else "",
                    "rssi": e["rssi"] if e else None, "age": round(now - e["t"], 1) if e else None,
                    "pps": (e["pps"] if e and now - e["t"] < 3 else 0), "n": e["n"] if e else 0})
    out.sort(key=lambda r: (r["act"] == 0, r["act"], r["age"] if r["age"] is not None else 1e9))
    return out

def on_core_radio(p):
    # CRSF frame 0x7B from the ESP receiver: mac(6) rssi(1) + NaviBoden packet of the Core (navi_proto.h, Core V2.72)
    if CFG.get("core_radio", "1") != "1" or len(p) < 7 + 53:
        return
    mac = ":".join("%02X" % b for b in p[:6])
    rssi = p[6] - 256 if p[6] > 127 else p[6]
    (magic, typ, proto, name, flags, nr, pct, t1, t2, t3, n1, n2, n3, wmv, vmv, wsek, lqp, lqs, kap, ch, wl,
     ver) = struct.unpack("<HBB8sBBB3h5s5s5sHHBBBHBB6s", bytes(p[7:7 + 53]))
    if magic != 0x564E or typ != 20:
        return
    txt = lambda b: b.split(b"\0", 1)[0].decode("ascii", "ignore")
    temps = [[txt(n) or "T%d" % (i + 1), round(t / 10.0)] for i, (n, t) in enumerate(((n1, t1), (n2, t2), (n3, t3))) if t != -32768]
    now = time.time()
    CORE_LIVE["d"] = {"temps": temps, "pct": pct or None, "nr": nr or None, "wet": bool(flags & 2), "armed": bool(flags & 1),
                      "via": "radio", "name": txt(name), "mac": mac, "rssi": rssi, "ch": ch, "ver": txt(ver)}
    CORE_LIVE["t"] = now
    CORE_RADIO["t"] = now
    CORE["ok"] = now
    if CFG.get("core_sync", "1") == "1":
        new = {"cell_warn": str(wmv / 1000.0), "cell_pre": str(vmv / 1000.0), "cell_warn_s": str(wsek), "lq_warn": str(lqp), "batt_mah": str(kap)}
        ch_ = [k for k, v in new.items() if v and CFG.get(k) != v]
        if ch_:
            for k in ch_:
                CFG[k] = new[k]
            save_cfg(CFG)

def on_me_gps(p):
    # CRSF frame 0x7C from the ESP receiver: own GPS (lat, lon int32 1e7, alt int16 m, km/h*10, course*10, sats, fix, hdop*10)
    if CFG.get("me_gps", "1") != "1" or len(p) < 17:
        return
    lat, lon, alt, kmh, crs, sats, fix, hd = struct.unpack("<iihHHBBB", bytes(p[:17]))
    with LOCK:
        ME.update(lat=lat / 1e7, lon=lon / 1e7, alt=alt, kmh=kmh / 10.0, crs=crs / 10.0, sats=sats, fix=fix, hdop=hd / 10.0, t=time.time())

def bearing(a, b, c, d):
    y = math.sin(math.radians(d - b)) * math.cos(math.radians(c))
    x = math.cos(math.radians(a)) * math.sin(math.radians(c)) - math.sin(math.radians(a)) * math.cos(math.radians(c)) * math.cos(math.radians(d - b))
    return (math.degrees(math.atan2(y, x)) + 360) % 360

def core_live_thread():
    # every 2 s while the Core is reachable over WLAN: temperatures, battery number/%, wet sensor
    while True:
        h = CORE.get("host") or (CFG.get("core_hosts", "").split() or [""])[0]
        ok = False
        if TEST["on"] or time.time() - CORE_RADIO["t"] < 4:   # test ride, or the Core is heard by radio (V1.8)
            time.sleep(1)
            continue
        if CFG.get("core_live", "1") == "1" and h:
            try:
                with urllib.request.urlopen("http://%s/api/status" % h, timeout=2) as r:
                    c = json.loads(r.read().decode("utf-8", "ignore"))
                temps = []
                for i, v in enumerate(c.get("t") or []):
                    n = (c.get("tn") or [])[i] if i < len(c.get("tn") or []) else "T%d" % (i + 1)
                    if v is not None and v > -40:
                        temps.append([n, round(float(v))])
                CORE_LIVE["d"] = {"temps": temps, "pct": c.get("akkuPct"), "nr": c.get("akkuNr"),
                                  "wet": bool(c.get("nass")), "armed": bool(c.get("armed")), "via": "wlan", "name": CFG.get("core_name", "mojave")}
                CORE_LIVE["t"] = time.time()
                ok = True
            except Exception:
                pass
        time.sleep(2 if ok else 10)

def backlight_path():
    g = glob.glob("/sys/class/backlight/*/brightness")
    return g[0] if g else None

def set_bright(pct):
    p = backlight_path()
    if not p:
        return False
    try:
        mx = int(open(os.path.join(os.path.dirname(p), "max_brightness")).read().strip())
        v = max(1, round(mx * max(5, min(100, pct)) / 100.0))
        open(p, "w").write(str(v))
        return True
    except Exception:
        return False

def ride_stats(fn, points=False):
    """Read one ride log. Returns stats (and points [lat, lon, kmh, lq] if wanted)."""
    pts, t0 = [], None
    drv = {}
    t1 = km = vmax = 0.0
    m0 = m1 = None
    lqmin = None
    last = None
    with open(fn) as f:
        next(f, None)
        for line in f:
            if line.startswith("#veh="):              # V2.0.6: name|colour|type|pilot of the sender
                f6 = (line[5:].strip() + "|||").split("|")
                drv["veh"] = {"name": f6[0], "col": f6[1], "type": f6[2] or "car", "pilot": f6[3]}
                continue
            if line.startswith("#driver="):           # V1.9.4
                for kv in line[1:].strip().split(";"):
                    k, _, v = kv.partition("=")
                    drv[k] = v
                continue
            c = line.strip().split(",")
            if len(c) < 13:
                continue
            try:
                t, la, lo, v = float(c[0]), float(c[1]), float(c[2]), float(c[3])
                mah = int(float(c[10])); lq = int(float(c[11])) if c[11] not in ("", "None") else None
                sats = int(float(c[6]))
            except Exception:
                continue
            if sats and sats < 5:                     # V2.0.9: bad GPS rows are left out
                continue
            if t0 is None:
                t0 = t
            t1 = t
            m0 = mah if m0 is None else m0
            m1 = mah
            vmax = max(vmax, v)
            if lq is not None:
                lqmin = lq if lqmin is None else min(lqmin, lq)
            jump = bool(last) and is_jump(last[0], last[1], last[2], la, lo, v, t)
            if last and not jump:
                km += haversine(last[0], last[1], la, lo) / 1000.0
            last = (la, lo, t)
            if points and (jump or not pts or haversine(pts[-1][0], pts[-1][1], la, lo) > 1.5 or t - pts[-1][4] > 5):
                try:
                    hd = round(float(c[4]))
                except Exception:
                    hd = 0
                def fl(i, nd=2):
                    try:
                        return round(float(c[i]), nd)
                    except Exception:
                        return None
                pts.append([round(la, 7), round(lo, 7), round(v, 1), lq, round(t, 1), hd, 1 if jump else 0,   # V2.0.5: + time, heading; V2.0.9: gap
                            fl(5, 0), fl(7), fl(8), fl(9, 1), mah, fl(12, 0), sats])   # V2.0.13: alt, volt, cell, amp, mah, rssi, sats for the replay tiles
    r = {"name": os.path.basename(fn), "t0": t0, "dur": round(t1 - t0) if t0 else 0, "km": round(km, 2),
         "vmax": round(vmax), "mah": max(0, (m1 or 0) - (m0 or 0)), "lqmin": lqmin,
         "driver": drv.get("driver", ""), "car2": drv.get("car2", ""),
         "t1": t1, "car": int(re.search(r"_(\d)_", os.path.basename(fn)).group(1)) if re.search(r"_(\d)_", os.path.basename(fn)) else 1,
         "plane": "(plane)" in drv.get("driver", "") or (drv.get("veh") or {}).get("type") == "plane", "veh": drv.get("veh")}
    if points:
        r["pts"] = pts
    return r

RIDE_CACHE = {}

def ride_files():
    """V2.0.5: stats of all ride logs (cached), newest first"""
    out = []
    for fn in sorted(glob.glob(os.path.join(BASE, "logs", "*.csv")), reverse=True)[:300]:
        try:
            st = os.stat(fn)
            key = (fn, st.st_size, int(st.st_mtime))
            if key not in RIDE_CACHE:
                RIDE_CACHE[key] = ride_stats(fn)
            out.append(RIDE_CACHE[key])
        except Exception:
            pass
    return out

def ride_overlap(a, b, margin=120):
    return a.get("t0") and b.get("t0") and a["t0"] - margin <= b["t1"] and b["t0"] - margin <= a["t1"]

def same_veh(a, b):
    """V2.0.13: the same model logged twice (e.g. it moved from slot 2 to the main slot) is not a second vehicle"""
    va, vb = a.get("veh") or {}, b.get("veh") or {}
    na, nb = va.get("name"), vb.get("name")
    pa, pb = (va.get("pilot") or "").strip(), (vb.get("pilot") or "").strip()
    return bool(na) and na == nb and (pa == pb or not pa or not pb)   # V2.0.16: two FUNJETs of different pilots are two planes

def ride_merge(a, b):
    """V2.0.13: puts the points of log b into ride a (same model, logged in two files) - joint = GPS gap"""
    w0, w1 = a.get("win", (a.get("t0") or 0, a.get("t1") or 0))
    pb = [list(p) for p in b.get("pts") or [] if w0 - 60 <= p[4] <= w1 + 60]   # V2.0.15: only the part at the time of this ride
    if not pb:
        return
    P = sorted((a.get("pts") or []) + pb, key=lambda p: p[4])
    for i in range(1, len(P)):                   # V2.0.15: gaps new from time + distance (the joint itself is no gap)
        q, p = P[i - 1], P[i]
        P[i][6] = 1 if is_jump(q[0], q[1], q[4], p[0], p[1], p[2] or 0, p[4]) else 0
    a["pts"] = P
    a["t0"], a["t1"] = P[0][4], P[-1][4]
    a["km"] = round((a.get("km") or 0) + (b.get("km") or 0), 2)
    a["vmax"] = max(a.get("vmax") or 0, b.get("vmax") or 0)
    a["mah"] = (a.get("mah") or 0) + (b.get("mah") or 0)
    if a.get("t0") and a.get("t1"):
        a["dur"] = round(a["t1"] - a["t0"])

def list_rides():
    """V2.0.5: car 1 rides carry the overlapping rides of car 2 ("with"); a car 2 ride is only listed on its own
    when no listed car 1 ride overlaps it"""
    allr = ride_files()
    real = lambda r: r["km"] * 1000 >= cf("ride_min_m") and r["vmax"] >= cf("ride_min_kmh") and (r.get("dur") or 0) >= cf("ride_min_s")   # V2.0.12: all three
    out = []
    for r in allr:
        if r.get("car", 1) != 1:
            continue
        w = [x for x in allr if x.get("car", 1) != 1 and ride_overlap(r, x) and real(x) and not same_veh(r, x)]
        if real(r) or w:
            out.append(dict(r, with_=[x["driver"] or x["name"] for x in w]))
    for x in allr:
        if x.get("car", 1) != 1 and real(x) and not any(ride_overlap(x, r) for r in out if r.get("car", 1) == 1):
            out.append(dict(x, with_=[]))
    out.sort(key=lambda r: r.get("t0") or 0, reverse=True)
    return out[:200]

def list_rides_old():
    out = []
    for fn in sorted(glob.glob(os.path.join(BASE, "logs", "*.csv")), reverse=True)[:200]:
        try:
            st = os.stat(fn)
            key = (fn, st.st_size, int(st.st_mtime))
            if key not in RIDE_CACHE:
                RIDE_CACHE[key] = ride_stats(fn)
            r = RIDE_CACHE[key]
            if r["km"] >= 0.05 or r["vmax"] >= 5:      # only real rides, not standing at home
                out.append(r)
        except Exception:
            pass
    return out

# V1.8.3: switch the Wi-Fi from the menu (saved NetworkManager connections)
WIFI_SW = {"busy": False, "msg": "", "target": "", "t0": 0.0}

def nm(*a, timeout=10):
    try:
        return subprocess.run(["nmcli"] + list(a), capture_output=True, text=True, timeout=timeout)
    except Exception:
        return None

def wifi_list():
    out = []
    r = nm("-t", "-f", "NAME,TYPE", "con", "show")
    vis = {}
    v = nm("-t", "-f", "SSID,SIGNAL", "dev", "wifi", "list", "--rescan", "no")
    if v:
        for line in v.stdout.splitlines():
            ss, _, sg = line.rpartition(":")
            ss = ss.replace("\\:", ":")
            if ss:
                vis[ss] = max(vis.get(ss, 0), int(sg or 0))
    for line in (r.stdout.splitlines() if r else []):
        name, _, typ = line.rpartition(":")
        if typ != "802-11-wireless":
            continue
        name = name.replace("\\:", ":")
        q = nm("-g", "802-11-wireless.ssid,connection.autoconnect-priority", "con", "show", name)
        ssid, prio = name, 0
        if q and q.stdout.strip():
            parts = q.stdout.strip().splitlines()
            ssid = parts[0] or name
            try:
                prio = int(parts[1])
            except Exception:
                pass
        out.append({"con": name, "ssid": ssid, "signal": vis.get(ssid), "active": ssid == HOME_WIFI.get("ssid"), "prio": prio})
    out.sort(key=lambda x: -x["prio"])
    return out

def wifi_scan():
    """V2.0.13: networks in range that are not saved yet (to add one with its password)"""
    saved = {w["ssid"] for w in wifi_list()}
    v = nm("-t", "-f", "SSID,SIGNAL,SECURITY", "dev", "wifi", "list", "--rescan", "no")
    out = {}
    for line in (v.stdout.splitlines() if v else []):
        f = re.split(r"(?<!\\):", line)
        if len(f) < 3:
            continue
        ss = f[0].replace("\\:", ":")
        if not ss or ss in saved:
            continue
        try:
            sg = int(f[1] or 0)
        except Exception:
            sg = 0
        if ss not in out or sg > out[ss]["signal"]:
            out[ss] = {"ssid": ss, "signal": sg, "open": f[2].strip() in ("", "--")}
    return sorted(out.values(), key=lambda x: -x["signal"])[:12]

def wifi_add(ssid, psk):
    """V2.0.13: connect to a new network and keep it (connects again by itself later)"""
    WIFI_SW.update(busy=True, msg="", target=ssid, t0=time.time())
    nm("dev", "wifi", "rescan", timeout=8)
    time.sleep(2)
    a = ["dev", "wifi", "connect", ssid] + (["password", psk] if psk else []) + ["ifname", CFG.get("wifi_dev", "wlan0")]
    r = nm(*a, timeout=45)
    ok = r is not None and r.returncode == 0
    if ok:
        wifi_fix_auto()
    WIFI_SW.update(busy=False, msg=("connected - saved" if ok else "failed: " + ((r.stderr or r.stdout).strip()[-120:] if r else "timeout")))

def wifi_fix_auto():
    """V2.0.13: every saved Wi-Fi connects by itself and keeps trying (NetworkManager gives up after 4 tries by default)"""
    for w in wifi_list():
        nm("con", "modify", w["con"], "connection.autoconnect", "yes", "connection.autoconnect-retries", "0")

def wifi_switch(con, ssid=""):
    WIFI_SW.update(busy=True, msg="", target=ssid or con, t0=time.time())
    nm("dev", "wifi", "rescan", timeout=8)
    time.sleep(2)
    r = nm("con", "up", "id", con, timeout=45)
    ok = r is not None and r.returncode == 0
    WIFI_SW.update(busy=False, msg=("connected" if ok else "failed: " + ((r.stderr or r.stdout).strip()[-120:] if r else "timeout")))

def wifi_thread():
    wifi_fix_auto()                              # V2.0.13
    # checks every 10 s whether the Pi is in the home WLAN (for VGPS)
    while True:
        ssid = ""
        for cmd in (["iwgetid", "-r"], ["nmcli", "-t", "-f", "active,ssid", "dev", "wifi"]):
            try:
                out = subprocess.run(cmd, capture_output=True, text=True, timeout=5).stdout
            except Exception:
                continue
            if cmd[0] == "iwgetid":
                ssid = out.strip()
            else:
                for line in out.splitlines():
                    if line.startswith("yes:"):
                        ssid = line[4:].strip()
            if ssid:
                break
        want = CFG.get("vgps_ssid", "").strip()
        try:                                     # V1.9.5: network cable plugged in = at home too
            lan = open("/sys/class/net/eth0/carrier").read().strip() == "1"
        except Exception:
            lan = False
        HOME_WIFI["ok"] = (not want) or ssid == want or lan
        HOME_WIFI["ssid"] = ssid
        # WLAN quality: signal (dBm) and ping time to the router (ms)
        sig = ms = None
        try:
            out = subprocess.run(["iw", "dev", CFG.get("wifi_dev", "wlan0"), "link"], capture_output=True, text=True, timeout=5).stdout
            for line in out.splitlines():
                if "signal:" in line:
                    sig = int(float(line.split("signal:")[1].split()[0]))
        except Exception:
            pass
        if ssid:
            try:
                gw = subprocess.run(["ip", "route", "show", "default"], capture_output=True, text=True, timeout=5).stdout.split()
                gw = gw[gw.index("via") + 1] if "via" in gw else ""
                if gw:
                    out = subprocess.run(["ping", "-c", "1", "-W", "2", gw], capture_output=True, text=True, timeout=5).stdout
                    if "time=" in out:
                        ms = round(float(out.split("time=")[1].split()[0]))
                    else:
                        ms = -1          # no answer
            except Exception:
                pass
        HOME_WIFI["sig"] = sig if ssid else None
        HOME_WIFI["ms"] = ms
        time.sleep(10)

DISARMED_MODES = ("OK", "WAIT", "!ERR", "!FS!")

def is_jump(la0, lo0, t0, la, lo, spd, t=None):
    """V2.0.9: True when the step from the last position is not believable (bad GPS / no data for a while):
    more than 30 m AND (more than gap_s without position OR faster than possible)"""
    if la0 is None or t0 is None:
        return False
    d = haversine(la0, lo0, la, lo)
    if d <= 30:
        return False
    dt = max(0.05, (t if t is not None else time.time()) - t0)
    # V2.0.15: planes send a position only every 2-5 s -> a pause alone is no jump any more, only a really long one (signal lost)
    return dt > cf("gap_s") or d / dt * 3.6 > max(150.0, 2 * spd + 40)

def is_disarmed(mode):
    m = (mode or "").strip().upper()
    return m in DISARMED_MODES or m.endswith("*")

ARM = {"since": None, "last": 0.0}   # armed-since timestamp, duration of the last armed phase

def set_mode(mode):
    S["mode"] = mode
    armed = bool(mode.strip()) and not is_disarmed(mode)
    if armed and ARM["since"] is None:
        ARM["since"] = time.time()
        if DIS.pop(1, None) is None:             # V2.0.11: armed again within log_stop_s -> same ride
            new_ride(1)                          # V2.0.8: arming starts a new ride / flight
    elif not armed and ARM["since"] is not None:
        ARM["last"] = time.time() - ARM["since"]
        ARM["since"] = None
        DIS[1] = time.time()                     # V2.0.10: disarmed = ride finished, log runs on for log_stop_s, then closes

def on_gps(lat, lon, spd, hdg, alt, sats, src):
    global TRACK
    with LOCK:
        got_data(src)
        nofix = sats < 4 or (abs(lat) < 1e-6 and abs(lon) < 1e-6)
        S["vgps"] = False
        if nofix and src != "TEST" and CFG.get("vgps", "0") == "1" and HOME_WIFI["ok"]:
            lat, lon, sats = cf("vgps_lat"), cf("vgps_lon"), ci("vgps_sats")
            S["vgps"] = True
        elif nofix:                              # V1.9.5: no fix = position not valid (FC sends old/garbage), keep the last one
            S.update(sats=sats, spd=spd, alt=alt)
            log_row()
            return
        # stand still: car disarmed or slower than still_kmh -> keep position/heading (no GPS jitter on the map)
        disarmed = CFG.get("freeze_disarmed", "1") == "1" and is_disarmed(S.get("mode"))
        still = spd < cf("still_kmh")              # V2.0.24: only real stand still (disarmed but moving, e.g. carried in a car, showed 0 km/h)
        if still and src != "TEST" and S["lat"] is not None and haversine(S["lat"], S["lon"], lat, lon) < cf("still_jump_m"):
            S.update(spd=0.0 if disarmed else spd, alt=alt, sats=sats, parked=True)
            log_row()
            return
        if S["lat"] is not None:
            step = haversine(S["lat"], S["lon"], lat, lon)
            if step < 200:                       # ignore GPS jumps
                S["trip"] = S.get("trip", 0.0) + step
        gap = is_jump(S.get("lat"), S.get("lon"), S.get("gts"), lat, lon, spd)   # V2.0.9: GPS was bad -> no line across the gap
        S.update(lat=lat, lon=lon, spd=spd, hdg=hdg, alt=alt, sats=sats, parked=False)
        S["gts"] = time.time()                  # V1.9.11: time of this position (smooth playback in the browser)
        if spd > S["maxspd"]:
            S["maxspd"] = spd
        if S["home"] is None and sats >= ci("home_min_sats") and (lat or lon):
            S["home"] = [lat, lon]; S["alt0"] = alt      # V2.0.7: height above the start point
        if S["home"]:
            S["dist"] = haversine(S["home"][0], S["home"][1], lat, lon)
        if not TRACK or haversine(TRACK[-1][0], TRACK[-1][1], lat, lon) > 2.0:
            TRACK.append([round(lat, 7), round(lon, 7), round(spd, 1)] + ([1] if gap else []))
            if len(TRACK) > 50000:
                TRACK = TRACK[-40000:]
        log_row()

MAH0 = {"v": None}

def on_batt(v, cur, mah, pct, src):
    global LOW_SINCE, PRE_SINCE
    with LOCK:
        got_data(src)
        n = cell_count(v)
        # consumption since start of the ride (counter of the car may already be > 0)
        if MAH0["v"] is None or mah < MAH0["v"] or (n and S["cells"] and v / n - S["cell"] > 0.3 and time.time() - LAST_RX > 30):
            MAH0["v"] = mah                     # first value, counter reset or new pack
        used = max(0, mah - MAH0["v"])
        cap = cf("batt_mah")
        S.update(v=v, cur=cur, mah=mah, pct=pct, cells=n, cell=(v / n if n else 0.0),
                 mah_used=used, left=(max(0, round(100 - used * 100.0 / cap)) if cap > 0 else None))
        if n and S["cell"] < cf("cell_warn"):
            LOW_SINCE = LOW_SINCE or time.time()
        else:
            LOW_SINCE = None
        if n and S["cell"] < cf("cell_pre"):
            PRE_SINCE = PRE_SINCE or time.time()
        else:
            PRE_SINCE = None

def on_link(rssi, lq, snr, rfmode, txpw, src):
    with LOCK:
        got_data(src)
        S.update(rssi=rssi, lq=lq, snr=snr, rfmode=rfmode, txpw=txpw)

# ---------------------------------------------------------------- V2.0: real car 2 (second sender)
C2RX = {"t": 0.0}
CX = {n: ({} if n > 2 else C2) for n in range(2, 7)}          # V2.0.6: vehicles on slots 2..6
TRK = {n: ([] if n > 2 else TRACK2) for n in range(2, 7)}
CXRX = {n: ({"t": 0.0} if n > 2 else C2RX) for n in range(2, 7)}
LOGX = {n: ({"f": None, "mac": None} if n > 2 else LOG2) for n in range(2, 7)}

def c_gps(n, lat, lon, spd, hdg, alt, sats):
    with LOCK:
        c, tr = CX[n], TRK[n]
        CXRX[n]["t"] = time.time()
        if sats < 4 or (abs(lat) < 1e-6 and abs(lon) < 1e-6):
            c.update(sats=sats, spd=spd, alt=alt)
            log_rowx(n)
            return
        disarmed = CFG.get("freeze_disarmed", "1") == "1" and is_disarmed(c.get("mode"))
        if spd < cf("still_kmh") and c.get("lat") is not None and haversine(c["lat"], c["lon"], lat, lon) < cf("still_jump_m"):
            c.update(spd=0.0 if disarmed else spd, alt=alt, sats=sats)
            log_rowx(n)
            return
        if c.get("lat") is not None:
            st = haversine(c["lat"], c["lon"], lat, lon)
            if st < 200:
                c["trip"] = c.get("trip", 0.0) + st
        gap = is_jump(c.get("lat"), c.get("lon"), c.get("gts"), lat, lon, spd)
        c.update(lat=lat, lon=lon, spd=spd, hdg=hdg, alt=alt, sats=sats, gts=time.time())
        c["maxspd"] = max(c.get("maxspd", 0.0), spd)
        if c.get("home") is None and sats >= ci("home_min_sats"):
            c["home"] = [lat, lon]; c["alt0"] = alt
        if c.get("home"):
            c["dist"] = haversine(c["home"][0], c["home"][1], lat, lon)
        if not tr or haversine(tr[-1][0], tr[-1][1], lat, lon) > 2.0:
            tr.append([round(lat, 7), round(lon, 7), round(spd, 1)] + ([1] if gap else []))
            if len(tr) > 50000:
                del tr[:-40000]
        log_rowx(n)

def c2_gps(lat, lon, spd, hdg, alt, sats):
    c_gps(2, lat, lon, spd, hdg, alt, sats)

def veh_line(sc):
    """V2.0.6: '#veh=' comment line of a ride log: name|colour|type|pilot of the sender"""
    sc = sc or {}
    return "#veh=%s|%s|%s|%s\n" % (sc.get("name", ""), sc.get("col", ""), sc.get("type", "car"), sc.get("pilot", ""))

def log_rowx(n):
    """V2.0.5: ride log of slot n >= 2 - same columns as car 1, own file per sender (logs/..._n_MODEL.csv)."""
    if CFG["log"] != "1" or TEST["on"]:
        return
    c, L = CX[n], LOGX[n]
    if c.get("lat") is None or log_off(c.get("mode"), n):
        return
    try:
        sc = slot_cfg(n) or {}
        if L["f"] is not None and L["mac"] != sc.get("mac"):
            L["f"].close(); L["f"] = None
        if L["f"] is None:
            os.makedirs(os.path.join(BASE, "logs"), exist_ok=True)
            model = re.sub(r"[^A-Za-z0-9_-]", "", (sc.get("name") or "car").replace(" ", "_"))[:14] or "car"
            fn = time.strftime("logs/%Y-%m-%d_%H%M%S") + "_%d_" % n + model + ".csv"
            if os.path.exists(os.path.join(BASE, fn)):
                fn = fn.replace(".csv", "_b.csv")
            L["f"] = open(os.path.join(BASE, fn), "w", buffering=1); L["mac"] = sc.get("mac")
            L["f"].write("time,lat,lon,kmh,heading,alt,sats,volt,cell,amp,mah,lq,rssi\n")
            drv = (sc.get("pilot") or "").strip()
            L["f"].write("#driver=%s;car2=%s\n" % ((drv + " - " if drv else "") + (sc.get("name") or "CAR %d" % n) + (" (plane)" if sc.get("type") == "plane" else ""), ""))
            L["f"].write(veh_line(sc))
        LROW[n] = time.time()
        L["f"].write("%.1f,%.7f,%.7f,%.1f,%.0f,%d,%d,%.2f,%.2f,%.1f,%d,%s,%s\n" % (
            time.time(), c["lat"], c["lon"], c.get("spd", 0.0), c.get("hdg", 0.0), c.get("alt", 0), c.get("sats", 0),
            c.get("v", 0.0), c.get("cell", 0.0), c.get("cur", 0.0), c.get("mah", 0), c.get("lq"), c.get("rssi")))
    except Exception:
        pass

def log_row2():
    log_rowx(2)

def c2_frame(t, p):
    c_frame(2, t, p)

def c_frame(n, t, p):
    """telemetry frame of the sender on slot n >= 2"""
    if t == 0x02 and len(p) >= 15:
        lat, lon, gs, hd, alt, sats = struct.unpack(">iiHHHB", p[:15])
        c_gps(n, lat / 1e7, lon / 1e7, gs / 10.0, hd / 100.0, alt - 1000, sats)
        return
    with LOCK:
        c = CX[n]
        CXRX[n]["t"] = time.time()
        if t == 0x08 and len(p) >= 8:
            v, cu = struct.unpack(">HH", p[:4])
            mah = (p[4] << 16) | (p[5] << 8) | p[6]
            v /= 10.0
            k = cell_count(v)
            if c.get("mah0") is None or mah < c["mah0"]:
                c["mah0"] = mah
            used = max(0, mah - c["mah0"])
            cap = cf("batt_mah")
            c.update(v=v, cur=cu / 10.0, mah=mah, pct=p[7], cells=k, cell=round(v / k, 2) if k else 0.0, mah_used=used,
                     left=(max(0, round(100 - used * 100.0 / cap)) if cap > 0 else None))
            if k and c["cell"] < cf("cell_warn"):
                c["low_since"] = c.get("low_since") or time.time()
            else:
                c["low_since"] = None
            if k and c["cell"] < cf("cell_pre"):
                c["pre_since"] = c.get("pre_since") or time.time()
            else:
                c["pre_since"] = None
        elif t == 0x14 and len(p) >= 10:
            r1, r2, lq, snr, ant, rf, pw = struct.unpack(">BBBbBBB", p[:7])
            r = r1 if (ant == 0 or r2 == 0) else r2
            c.update(rssi=(r - 256 if r > 127 else -r), lq=lq, snr=snr)
        elif t == 0x1E and len(p) >= 6:
            pi, ro, ya = struct.unpack(">hhh", p[:6])
            c.update(pitch=round(math.degrees(pi / 10000.0), 1), roll=round(math.degrees(ro / 10000.0), 1))
        elif t == 0x21:
            m = p.split(b"\0", 1)[0].decode("ascii", "ignore")[:16]
            c["mode"] = m
            armed = bool(m.strip()) and not is_disarmed(m)
            if armed and not c.get("arm0"):
                c["arm0"] = time.time()
                if DIS.pop(n, None) is None:   # V2.0.11: armed again within log_stop_s -> same flight
                    new_ride(n)     # V2.0.8: arming starts a new flight
            elif not armed and c.get("arm0"):
                c["arm_last"] = time.time() - c["arm0"]; c["arm0"] = None; DIS[n] = time.time()   # V2.0.10
            c["armed"] = armed

def log_names():
    """V1.9.4: driver names go into the ride log as a comment line (the last one counts)."""
    if LOG["f"]:
        n = (CFG.get("names", "") + ",").split(",")
        sc = slot_cfg(1)
        if sc:                                   # V2.0.6: pilot - model of the sender on the main slot
            n[0] = ((sc.get("pilot") + " - ") if sc.get("pilot") else "") + (sc.get("name") or "") + (" (plane)" if sc.get("type") == "plane" else "")
        LOG["f"].write("#driver=%s;car2=%s\n" % (n[0].strip(), n[1].strip()))
        if sc:
            LOG["f"].write(veh_line(sc))

def new_ride(n):
    """V2.0.8: close the ride log of slot n -> the next GPS position starts a new file; trip and max speed start at 0"""
    L = LOG if n == 1 else LOGX[n]
    if L["f"]:
        try:
            L["f"].close()
        except Exception:
            pass
        L["f"] = None
    if n == 1:
        S["trip"] = 0.0; S["maxspd"] = 0.0
    else:
        CX[n]["trip"] = 0.0; CX[n]["maxspd"] = 0.0

DIS = {}   # V2.0.10: slot -> time of disarming
LROW = {}  # V2.0.11: slot -> time of the last logged row

def ride_gap():
    """V2.0.11: no telemetry for ride_gap_s -> close the ride log (the next data start a new ride)"""
    now = time.time()
    for n, t in list(LROW.items()):
        if now - t > cf("ride_gap_s"):
            LROW.pop(n, None)
            L = LOG if n == 1 else LOGX.get(n)
            if L and L["f"]:
                new_ride(n)

def log_off(mode, n=1):
    """V2.0.8: a flight controller says DISARMED -> nothing is logged (no long standing logs between flights).
    V2.0.10: after disarming the log runs on for log_stop_s seconds, then the ride is closed (always, also with log_disarmed=1)."""
    t = DIS.get(n)
    if t is not None:
        if time.time() - t < cf("log_stop_s"):
            return False
        DIS.pop(n, None); new_ride(n)            # ride finished
    return bool((mode or "").strip()) and is_disarmed(mode) and CFG.get("log_disarmed", "0") != "1"

def log_row():
    if CFG["log"] != "1" or log_off(S.get("mode")):
        return
    try:
        if LOG["f"] is None:
            os.makedirs(os.path.join(BASE, "logs"), exist_ok=True)
            fn = time.strftime("logs/%Y-%m-%d_%H%M%S") + ("_test" if TEST["on"] else "") + ".csv"
            while os.path.exists(os.path.join(BASE, fn)):          # V2.0.8: two rides in the same second
                fn = fn.replace(".csv", "b.csv")
            LOG["f"] = open(os.path.join(BASE, fn), "x", buffering=1)
            LOG["f"].write("time,lat,lon,kmh,heading,alt,sats,volt,cell,amp,mah,lq,rssi\n")
            log_names()
        LROW[1] = time.time()
        LOG["f"].write("%.1f,%.7f,%.7f,%.1f,%.0f,%d,%d,%.2f,%.2f,%.1f,%d,%s,%s\n" % (
            time.time(), S["lat"], S["lon"], S["spd"], S["hdg"], S["alt"], S["sats"],
            S["v"], S["cell"], S["cur"], S["mah"], S["lq"], S["rssi"]))
    except Exception:
        pass

# ---------------------------------------------------------------- V2.0.2: CPU / RAM / temperature of the Pi
SYS = {"t": 0.0, "d": None, "cpu": None}

def sys_load_win(d):
    import ctypes
    class MS(ctypes.Structure):
        _fields_ = [("l", ctypes.c_ulong), ("load", ctypes.c_ulong), ("tot", ctypes.c_ulonglong), ("av", ctypes.c_ulonglong),
                    ("a", ctypes.c_ulonglong), ("b", ctypes.c_ulonglong), ("c", ctypes.c_ulonglong), ("e", ctypes.c_ulonglong), ("f", ctypes.c_ulonglong)]
    m = MS(); m.l = ctypes.sizeof(MS)
    if ctypes.windll.kernel32.GlobalMemoryStatusEx(ctypes.byref(m)):
        d["ram"] = int(m.load); d["ram_mb"] = round((m.tot - m.av) / 1048576); d["ram_tot"] = round(m.tot / 1048576)
    ft = [ctypes.c_ulonglong() for _ in range(3)]
    if ctypes.windll.kernel32.GetSystemTimes(*[ctypes.byref(x) for x in ft]):
        idle, k, u = (x.value for x in ft)
        if SYS["cpu"]:
            di, dt = idle - SYS["cpu"][0], (k + u) - SYS["cpu"][1]
            d["cpu"] = round(100.0 * (1 - di / dt)) if dt > 0 else 0
        SYS["cpu"] = (idle, k + u)

def sys_load():
    now = time.time()
    if SYS["d"] and now - SYS["t"] < 2.0:
        return SYS["d"]
    d = {}
    if WIN:
        try:
            sys_load_win(d)
        except Exception:
            pass
        SYS["d"], SYS["t"] = d, now
        return d
    try:
        with open("/proc/stat") as f:
            v = [int(x) for x in f.readline().split()[1:]]
        idle, tot = v[3] + (v[4] if len(v) > 4 else 0), sum(v)
        if SYS["cpu"]:
            di, dt = idle - SYS["cpu"][0], tot - SYS["cpu"][1]
            d["cpu"] = round(100.0 * (1 - di / dt)) if dt > 0 else 0
        SYS["cpu"] = (idle, tot)
    except Exception:
        pass
    try:
        m = {}
        with open("/proc/meminfo") as f:
            for line in f:
                k, v = line.split(":", 1)
                m[k] = int(v.split()[0])
        d["ram"] = round(100.0 * (1 - m["MemAvailable"] / m["MemTotal"]))
        d["ram_mb"] = round((m["MemTotal"] - m["MemAvailable"]) / 1024)
        d["ram_tot"] = round(m["MemTotal"] / 1024)
        if m.get("SwapTotal"):
            d["swap_mb"] = round((m["SwapTotal"] - m["SwapFree"]) / 1024)
    except Exception:
        pass
    try:
        with open("/sys/class/thermal/thermal_zone0/temp") as f:
            d["temp"] = round(int(f.read()) / 1000.0)
    except Exception:
        pass
    SYS["d"], SYS["t"] = d, now
    return d

# ---------------------------------------------------------------- V2.0.26: online update from GitHub (like the Core / Navi)
UPD_URL = "https://raw.githubusercontent.com/magixfly/-mojave-updates/main/bodenstation/"
UPD = {"busy": False, "prog": 0, "msg": "", "online": None, "neu": [], "t": 0.0, "files": []}

def _vt(v):
    try:
        return tuple(int(x) for x in str(v).lstrip("Vv").split("."))
    except Exception:
        return (0,)

def upd_check():
    try:
        with urllib.request.urlopen(urllib.request.Request(UPD_URL + "manifest.json", headers={"User-Agent": "CoreTracker/" + VERSION}), timeout=10) as r:
            m = json.loads(r.read().decode("utf-8", "ignore"))
        UPD.update(online=str(m.get("ver") or ""), neu=list(m.get("neu") or [])[:12], files=list(m.get("dateien") or []), t=time.time(),
                   msg="")
    except Exception as e:
        UPD.update(msg="no connection to GitHub", t=time.time())
    return UPD

def upd_install():
    import hashlib
    UPD.update(busy=True, prog=1, msg="checking …")
    try:
        upd_check()
        fs = [f for f in UPD["files"] if f.get("p") and not f["p"].startswith("/") and ".." not in f["p"]]
        if not fs or _vt(UPD["online"]) <= _vt(VERSION):
            UPD.update(msg="already up to date")
            return
        tot = sum(int(f.get("s") or 1) for f in fs) or 1
        got = 0
        new = []
        for f in fs:                                 # 1) download everything as *.new and check MD5
            UPD["msg"] = "downloading " + f["p"]
            with urllib.request.urlopen(urllib.request.Request(UPD_URL + f["p"], headers={"User-Agent": "CoreTracker/" + VERSION}), timeout=30) as r:
                data = r.read()
            if f.get("md5") and hashlib.md5(data).hexdigest() != f["md5"]:
                UPD["msg"] = "MD5 error %s - try again in 5 min (GitHub cache)" % f["p"]
                return
            dst = os.path.join(BASE, f["p"])
            os.makedirs(os.path.dirname(dst), exist_ok=True)
            with open(dst + ".new", "wb") as o:
                o.write(data)
            new.append(dst)
            got += int(f.get("s") or 1)
            UPD["prog"] = min(95, int(got * 95 / tot))
        for dst in new:                               # 2) all good: keep the old file as *.bak, put the new one in place
            if os.path.exists(dst):
                shutil.copy2(dst, dst + ".bak")
            os.replace(dst + ".new", dst)
        UPD.update(prog=100, msg="installed %s - restarting …" % UPD["online"])
        time.sleep(1.0)
        os.execv(sys.executable, [sys.executable] + sys.argv)   # restart the program, the page reloads by itself
    except Exception as e:
        UPD["msg"] = "update failed: %s" % e
    finally:
        UPD["busy"] = False

def upd_thread():
    time.sleep(60)
    while True:
        upd_check()
        time.sleep(6 * 3600)

def batt_view(d, sc, cl, mah, fc_pct):
    """V2.0.25: which mAh / % left a vehicle shows
    - car with the Core (Mojave): the Core's values (it knows pack and charge, same as Navi)
    - plane (iNav): the flight controller's own values (mAh counter since FC start, % left from iNav)
    - other cars: nothing (we would only count since the tracker started -> wrong)"""
    if not sc:
        return
    if cl and cl.get("pct") is not None and not cl.get("demo") and (sc.get("name") or "").lower() == (cl.get("name") or "").lower():
        d["left"] = int(cl["pct"])
        d["mah_used"] = int(round(cf("batt_mah") * (100 - d["left"]) / 100.0)) if cf("batt_mah") > 0 else None
    elif sc.get("type") == "plane":
        d["mah_used"] = int(mah) if mah is not None else None
        d["left"] = int(fc_pct) if fc_pct is not None and 0 <= fc_pct <= 100 else None
    else:
        d["mah_used"] = None
        d["left"] = None

def claude_remote():
    """V2.0.28: Claude works on the Pi remotely (Pi Connect shell) -> it touches /tmp/claude_remote every 30 s"""
    try:
        return time.time() - os.path.getmtime("/tmp/claude_remote") < 90
    except Exception:
        return False

def snapshot():
    with LOCK:
        for n in list(DIS):                      # V2.0.10: close a disarmed ride also when no more GPS comes
            log_off("", n)
        ride_gap()
        d = dict(S)
        d["age"] = round(time.time() - LAST_RX, 1) if LAST_RX else 99.0
        d["claude"] = claude_remote()
        if TEST["on"] and PLAY["pause"]:
            d["age"] = 0.0                     # paused demo is not a lost link
        d["test"] = TEST["on"]
        d["test_cars"] = TEST.get("cars", 1) if TEST["on"] else 0
        if TEST["on"] and PLAY["len"]:
            d["play"] = {"t": round(PLAY["t"], 1), "len": round(PLAY["len"], 1), "speed": PLAY["speed"], "pause": PLAY["pause"]}
        d["track_len"] = len(TRACK)
        d["mac1"] = SLOTMAC.get(1)              # V2.0.8: other sender on the main view -> browser reloads the track
        d["lim"] = {"cell_warn": cf("cell_warn"), "cell_pre": cf("cell_pre"), "lq_warn": ci("lq_warn"),
                    "core": round(time.time() - CORE["ok"]) if CORE["ok"] else None}
        w = []
        if d["age"] > cf("link_timeout_s"):
            w.append("NO TELEMETRY" if LAST_RX else "WAITING FOR TELEMETRY")
        if LOW_SINCE and time.time() - LOW_SINCE >= cf("cell_warn_s"):
            w.append("LOW BATTERY %.2f V/CELL" % d["cell"])
        elif PRE_SINCE and time.time() - PRE_SINCE >= cf("cell_warn_s"):
            w.append("BATTERY %.2f V/CELL" % d["cell"])
        if d["lq"] is not None and ci("lq_warn") > 0 and d["lq"] < ci("lq_warn") and d["age"] <= cf("link_timeout_s"):
            w.append("WEAK LINK %d %%" % d["lq"])
        if d["vgps"]:
            pass
        elif d["lat"] is not None and d["sats"] < 5:
            w.append("WEAK GPS (%d SATS)" % d["sats"])
        d["armed"] = ARM["since"] is not None
        d["arm_s"] = round(time.time() - ARM["since"]) if ARM["since"] else (round(ARM["last"]) if ARM["last"] else None)
        d["imp"] = {k: IMP[k] for k in ("running", "done", "total", "copied", "skipped", "msg")} if (IMP["running"] or time.time() - IMP["t"] < 15) else None
        e = d.get("esp")
        d["esp"] = None if not e else {"rssi": e["rssi"], "pps": e["pps"], "bad": e["bad"], "age": round(time.time() - e["t"], 1)}
        d["sys"] = sys_load()                 # V2.0.2: CPU / RAM / temperature for the top bar
        d["dl"] = len(DL_WANT)
        if PRE["running"]:                       # V2.0.16: map preload progress for the status bar
            d["pre"] = {"done": PRE["done"], "total": PRE["total"]}                 # tiles waiting for / being downloaded from the internet
        d["wifi"] = {"ssid": HOME_WIFI.get("ssid", ""), "sig": HOME_WIFI.get("sig"), "ms": HOME_WIFI.get("ms")}
        me = None
        if ME["t"] and time.time() - ME["t"] < cf("me_timeout_s") and ME.get("fix") and (ME.get("lat") or ME.get("lon")):
            me = {k: ME[k] for k in ("lat", "lon", "alt", "kmh", "crs", "sats", "hdop")}
            me["age"] = round(time.time() - ME["t"], 1)
            if d["lat"] is not None:
                me["dist"] = round(haversine(me["lat"], me["lon"], d["lat"], d["lon"]), 1)
                me["brg"] = round(bearing(me["lat"], me["lon"], d["lat"], d["lon"]), 1)
                me["dalt"] = round((d.get("alt") or 0) - (me.get("alt") or 0))
        elif ME["t"] and time.time() - ME["t"] < 30:
            me = {"nofix": True, "sats": ME.get("sats", 0)}
        d["me"] = me
        far = me.get("dist") if me and me.get("dist") is not None else d.get("dist")
        if ci("range_warn_m") > 0 and far and far > ci("range_warn_m") and not TEST["on"]:   # V1.9.2: no FAR in the replay
            w.append("FAR %d M" % far)
        cl = CORE_LIVE["d"] if time.time() - CORE_LIVE["t"] < 8 else None
        d["core"] = cl
        d["model"] = (cl.get("name") or "core").upper() if cl else ""
        if cl and cl.get("wet"):
            w.append("CAR WET")
        d["sound"] = CFG.get("sound", "1") == "1"
        d["bright"] = ci("bright")
        d["warn"] = " · ".join(w)
        # V2.0: settings of the senders on car 1 / car 2 (name, type, symbol, colour) for the page
        d["slots"] = {str(n): slot_cfg(n) for n in range(1, vmax() + 1)}
        s1 = d["slots"]["1"]
        if s1 and s1["mac"] in SEEN and d["esp"]:
            d["esp"]["rssi"] = round(SEEN[s1["mac"]]["rssi"])     # ESP dBm of car 1's own sender
        # V2.0.23: % left of the car with the Core = the Core's value (it knows the pack and its charge, same as Navi/Core display);
        # our own value only counts mAh since the tracker started
        if not TEST["on"]:
            batt_view(d, s1, cl, S.get("mah"), S.get("pct"))
        d["act"] = sorted(ACT.keys())
        d["ralt"] = round(S["alt"] - S["alt0"]) if S.get("alt0") is not None and S.get("alt") is not None and S.get("lat") is not None else None
        vs = []                                  # V2.0.6: all other vehicles (slots 2..6), each with its slot number "n"
        for n in range(2, vmax() + 1):
            C, RX = CX[n], CXRX[n]
            real = not TEST["on"] and d["slots"].get(str(n)) is not None and time.time() - RX["t"] < max(60.0, cf("veh_timeout_s"))
            if real:
                sn = d["slots"][str(n)]
                e2 = SEEN.get(sn["mac"])
                C["esp"] = round(e2["rssi"]) if e2 else None
                C["esp_pps"] = e2["pps"] if e2 and time.time() - e2["t"] < 3 else 0
                C["age"] = round(time.time() - RX["t"], 1)
                C["arm_s"] = round(time.time() - C["arm0"]) if C.get("arm0") else (round(C["arm_last"]) if C.get("arm_last") else None)
            if not ((n == 2 and TEST["on"] and TEST.get("cars") == 2 and C.get("lat") is not None) or real):
                continue
            c = {k: v for k, v in C.items() if k not in ("t0", "pv", "mah0", "low_since", "pre_since", "arm0", "arm_last")}
            c["n"] = n
            if real:
                batt_view(c, d["slots"].get(str(n)), cl, C.get("mah"), C.get("pct"))
            c["track_len"] = len(TRK[n])
            c["ralt"] = round(c["alt"] - c["alt0"]) if c.get("alt0") is not None and c.get("alt") is not None and c.get("lat") is not None else None
            w2 = []
            if real and c.get("age", 0) > cf("link_timeout_s"):
                w2.append("NO TELEMETRY")
            elif real and c.get("lat") is None:
                w2.append("NO GPS FIX (%d SATS)" % (c.get("sats") or 0))
            ls, ps = C.get("low_since"), C.get("pre_since")
            if real and ls and time.time() - ls >= cf("cell_warn_s"):
                w2.append("LOW BATTERY %.2f V/CELL" % c["cell"])
            elif real and ps and time.time() - ps >= cf("cell_warn_s"):
                w2.append("BATTERY %.2f V/CELL" % c["cell"])
            elif not real and c.get("cell") and c["cell"] < cf("cell_warn"):
                w2.append("LOW BATTERY %.2f V/CELL" % c["cell"])
            elif not real and c.get("cell") and c["cell"] < cf("cell_pre"):
                w2.append("BATTERY %.2f V/CELL" % c["cell"])
            if ci("lq_warn") > 0 and c.get("lq") is not None and c["lq"] < ci("lq_warn") and c.get("age", 0) <= cf("link_timeout_s"):
                w2.append("WEAK LINK %d %%" % c["lq"])
            f2 = (haversine(me["lat"], me["lon"], c["lat"], c["lon"]) if me and me.get("lat") is not None else c.get("dist")) if c.get("lat") is not None else None
            if ci("range_warn_m") > 0 and f2 and f2 > ci("range_warn_m") and not TEST["on"]:
                w2.append("FAR %d M" % f2)
            c["warn"] = " · ".join(w2)
            vs.append(c)
        if vs:
            d["car2"] = vs[0]
            d["vs"] = vs
        return d

# ---------------------------------------------------------------- CRSF parser
def crc8(data):
    c = 0
    for b in data:
        c ^= b
        for _ in range(8):
            c = ((c << 1) ^ 0xD5) & 0xFF if c & 0x80 else (c << 1) & 0xFF
    return c

class Crsf:
    def __init__(self, src):
        self.buf = bytearray()
        self.src = src
        self.slot = 1                            # V2.0: car slot of the following telemetry (old ESP firmware: always car 1)

    def feed(self, data):
        b = self.buf
        b += data
        while len(b) >= 2:
            if b[0] not in (0xC8, 0xEA, 0xEE, 0xEC):
                del b[0]; continue
            n = b[1]
            if n < 2 or n > 62:
                del b[0]; continue
            if len(b) < n + 2:
                break
            fr = bytes(b[2:2 + n])
            if crc8(fr[:-1]) != fr[-1]:
                del b[0]; continue
            del b[:n + 2]
            try:
                self.frame(fr[0], fr[1:-1])
            except Exception:
                pass
        if len(b) > 4096:
            del b[:-256]

    def frame(self, t, p):
        if t == 0x7C:                            # own GPS from the ESP receiver (V1.8) - also during the test ride
            on_me_gps(p)
            return
        if t == 0x7D and len(p) >= 7:            # V2.0: sender mark from ESP firmware 1.3 (MAC + dBm) before each telemetry frame
            mac = ":".join("%02X" % b for b in p[:6])
            with LOCK:
                self.slot = sender_heard(mac, p[6] - 256 if p[6] > 127 else p[6])
            return
        if TEST["on"] and t != 0x7A:            # test ride: real telemetry ignored, ESP quality still shown
            return
        if t in (0x02, 0x08, 0x14, 0x1E, 0x21) and self.slot != 1:
            if self.slot >= 2:
                c_frame(self.slot, t, p)
            return
        if t == 0x7B:                            # Core broadcast heard by the ESP receiver (V1.8)
            on_core_radio(p)
            return
        if t == 0x02 and len(p) >= 15:
            lat, lon, gs, hd, alt, sats = struct.unpack(">iiHHHB", p[:15])
            on_gps(lat / 1e7, lon / 1e7, gs / 10.0, hd / 100.0, alt - 1000, sats, self.src)
        elif t == 0x08 and len(p) >= 8:
            v, c = struct.unpack(">HH", p[:4])
            mah = (p[4] << 16) | (p[5] << 8) | p[6]
            on_batt(v / 10.0, c / 10.0, mah, p[7], self.src)
        elif t == 0x14 and len(p) >= 10:
            r1, r2, lq, snr, ant, rf, pw = struct.unpack(">BBBbBBB", p[:7])
            r = r1 if (ant == 0 or r2 == 0) else r2
            on_link(r - 256 if r > 127 else -r, lq, snr, rf, pw, self.src)
        elif t == 0x1E and len(p) >= 6:
            pi, ro, ya = struct.unpack(">hhh", p[:6])
            with LOCK:
                S["pitch"] = round(math.degrees(pi / 10000.0), 1)
                S["roll"] = round(math.degrees(ro / 10000.0), 1)
        elif t == 0x21:
            with LOCK:
                set_mode(p.split(b"\0", 1)[0].decode("ascii", "ignore")[:16])
        elif t == 0x7A and len(p) >= 3:          # own frame from the ESP-NOW receiver (V1.1)
            with LOCK:
                r = p[0] - 256 if p[0] > 127 else p[0]
                S["esp"] = {"rssi": r if r else None, "pps": p[1], "bad": p[2], "t": time.time()}

# ---------------------------------------------------------------- serial reader
def find_dev_win():
    """Windows: COM port of the ESP32 receiver (Espressif USB VID 303A first, then other USB serial adapters)"""
    try:
        from serial.tools import list_ports
    except Exception:
        return None
    if CFG["serial"] != "auto":
        return CFG["serial"]
    ps = list(list_ports.comports())
    for p in ps:
        if p.vid == 0x303A:
            return p.device
    for p in ps:
        if p.vid in (0x10C4, 0x1A86, 0x0403):    # CP210x, CH340, FTDI
            return p.device
    return None

def find_dev():
    if WIN:
        return find_dev_win()
    if CFG["serial"] != "auto":
        return CFG["serial"] if os.path.exists(CFG["serial"]) else None
    for pat in ("/dev/ttyACM*", "/dev/ttyUSB*"):
        d = sorted(glob.glob(pat))
        if d:
            return d[0]
    if os.path.exists("/dev/serial0") and os.access("/dev/serial0", os.R_OK | os.W_OK):   # V2.0: ESP on the GPIO UART
        return "/dev/serial0"
    return None

def open_serial(dev, baud):
    import termios, tty
    fd = os.open(dev, os.O_RDWR | os.O_NOCTTY | os.O_NONBLOCK)
    tty.setraw(fd)
    a = termios.tcgetattr(fd)
    sp = getattr(termios, "B%d" % baud, termios.B115200)
    a[4] = a[5] = sp
    termios.tcsetattr(fd, termios.TCSANOW, a)
    return fd

def serial_win(dev):
    try:
        import serial
        sp = serial.Serial(dev, ci("baud"), timeout=1.0)
    except Exception as e:
        print("serial open failed", dev, e)
        time.sleep(2)
        return
    print("serial open", dev)
    with LOCK:
        S["dev"] = dev
    p = Crsf("USB")
    try:
        while True:
            d = sp.read(sp.in_waiting or 1)
            if d:
                p.feed(d)
    except Exception as e:
        print("serial lost", e)
    try:
        sp.close()
    except Exception:
        pass
    with LOCK:
        S["dev"] = ""
    time.sleep(1)

def serial_thread():
    while True:
        dev = find_dev()
        if not dev:
            with LOCK:
                S["dev"] = ""
            time.sleep(2); continue
        if WIN:
            serial_win(dev)
            continue
        try:
            fd = open_serial(dev, ci("baud"))
        except Exception as e:
            print("serial open failed", dev, e)
            time.sleep(2); continue
        print("serial open", dev)
        with LOCK:
            S["dev"] = dev
        p = Crsf("UART" if "serial" in dev or "ttyAMA" in dev or "ttyS" in dev else "USB")
        try:
            while True:
                r, _, _ = select.select([fd], [], [], 1.0)
                if r:
                    d = os.read(fd, 1024)
                    if not d:
                        raise OSError("closed")
                    p.feed(d)
        except Exception as e:
            print("serial lost", e)
        try:
            os.close(fd)
        except Exception:
            pass
        with LOCK:
            S["dev"] = ""
        time.sleep(1)

# ---------------------------------------------------------------- test ride
def load_demo():
    """Demo ride for the test mode (demo_ride.csv: t,lat,lon,kmh,alt,kurs,akkuV,A,mAh,t1,t2,t3,roll,nick,sats,lq,dbm)."""
    fn = CFG.get("test_ride", "demo_ride.csv")
    fn = fn if os.path.isabs(fn) else os.path.join(BASE, fn)
    rows = []
    try:
        with open(fn) as f:
            head = None
            for line in f:
                if line.startswith("#") or not line.strip():
                    continue
                c = line.strip().split(",")
                if head is None:
                    head = c
                    continue
                d = dict(zip(head, c))
                try:
                    rows.append({k: float(v) for k, v in d.items() if v not in ("", None)})
                except ValueError:
                    continue
    except Exception:
        return []
    return [r for r in rows if "t" in r and "lat" in r and "lon" in r]

PLAY = {"t": 0.0, "len": 0.0, "speed": 1.0, "pause": False, "seek": None}   # V1.8.1: test ride player (speed, timeline, pause)

def car2_reset():
    with LOCK:
        TRACK2.clear()
        C2.clear()

def car2_step(rows, cum, i, vt):
    """V1.9 demo: second car drives the same ride 5 m behind, 1.5 m to the right."""
    if TEST.get("cars") != 2:
        return
    # V1.9.2: gap changes slowly (-8 m ahead ... +30 m behind = overtaking and falling back), never drives backwards,
    # side offset swings +-4 m (lanes cross) but keeps >= 3 m beside the other car while they are close (no driving on top)
    # V1.9.14: start = car 2 about 6 m ahead of car 1 and 3 m to the right (side by side, not on top), then blend into the play
    w = max(0.0, min(1.0, (vt - 8.0) / 25.0)); w = w * w * (3 - 2 * w)
    gap = -6.0 * (1 - w) + (11.0 + 19.0 * math.sin(2 * math.pi * (vt - 8.0) / 75.0)) * w
    s = min(cum[i] - gap, cum[-1])
    pv = C2.get("pv")
    if pv and vt > pv[2] and s < pv[3]:
        s = pv[3]                               # no reversing when car 1 is slow
    side = 3.0 * (1 - w) + 4.0 * math.sin(2 * math.pi * (vt - 8.0) / 33.0 + 0.85) * w
    if abs(gap) < 14.0 and abs(side) < 3.5:     # V1.9.14: move aside early before overtaking
        side = 3.5 if (pv[4] if pv else side) >= 0 else -3.5
    if pv:                                      # side offset changes max 2 m/s
        dt = max(0.0, vt - pv[2])
        side = pv[4] + max(-2.0 * dt, min(2.0 * dt, side - pv[4]))
    def pos_at(x):
        if x <= 0:
            return rows[0]["lat"], rows[0]["lon"]
        j = min(len(cum) - 1, max(1, bisect.bisect_left(cum, x)))
        a, b = rows[j - 1], rows[j]
        seg = cum[j] - cum[j - 1]
        f = max(0.0, min(1.0, (x - cum[j - 1]) / seg)) if seg > 0 else 0.0
        return a["lat"] + (b["lat"] - a["lat"]) * f, a["lon"] + (b["lon"] - a["lon"]) * f
    lat, lon = pos_at(s)
    p0, p1 = pos_at(s - 4.0), pos_at(s + 4.0)      # heading over 8 m of path: no spinning on GPS jitter
    if s > 4.0 and haversine(p0[0], p0[1], p1[0], p1[1]) > 3.0:
        hdg = bearing(p0[0], p0[1], p1[0], p1[1])
    else:
        hdg = C2.get("hdg") if C2.get("hdg") is not None else rows[0].get("kurs", 0.0)
    off = math.radians(hdg + 90)
    lat += side * math.cos(off) / 111320.0
    lon += side * math.sin(off) / (111320.0 * math.cos(math.radians(lat)))
    # V1.9.14: never on top of car 1 - if closer than 3.5 m, push car 2 sideways until it is 3.5 m away
    if S.get("lat") is not None:
        for _ in range(3):
            dd = haversine(S["lat"], S["lon"], lat, lon)
            if dd >= 3.5:
                break
            sg = 1.0 if side >= 0 else -1.0
            push = (3.6 - dd) * sg
            lat += push * math.cos(off) / 111320.0
            lon += push * math.sin(off) / (111320.0 * math.cos(math.radians(lat)))
    spd = C2.get("spd", 0.0)
    if pv and vt > pv[2]:                       # speed along the path, smoothed
        spd = spd * 0.6 + 0.4 * min(120.0, max(0.0, (s - pv[3]) / (vt - pv[2]) * 3.6))
    elif not pv:
        spd = 0.0
    r = rows[i]
    frac = vt / PLAY["len"] if PLAY["len"] else 0
    cell = 4.02 - 0.42 * frac - spd * 0.0008 + random.uniform(-0.005, 0.005)
    lq = int(max(20, min(100, r.get("lq", 95) - 22 + random.uniform(-4, 4))))
    with LOCK:
        c = C2
        if c.get("lat") is not None:
            st = haversine(c["lat"], c["lon"], lat, lon)
            if st < 200:
                c["trip"] = c.get("trip", 0.0) + st
        if c.get("home") is None:
            c["home"] = [lat, lon]; c["alt0"] = r.get("alt", 268); c["t0"] = time.time()
        c["pv"] = (lat, lon, vt, s, side)
        c["gts"] = time.time()
        c.update(lat=lat, lon=lon, spd=spd, hdg=hdg, alt=int(r.get("alt", 268)) + 1, sats=9, cells=4, cell=round(cell, 2),
                 v=round(cell * 4, 2), cur=round(spd * 0.6, 1), lq=lq,
                 rssi=int(r.get("dbm", -60)) - 12, esp=-71 + random.randint(-2, 2), esp_pps=18, mode="MANU", armed=True)
        # V1.9.3: demo charge follows the voltage (3.45 V = 0 %, 4.05 V = 100 %), used mAh fits a 2200 mAh pack
        c["left"] = int(max(0, min(100, round((cell + spd * 0.0008 - 3.45) / 0.60 * 100))))
        c["mah_used"] = int(2200 * (100 - c["left"]) / 100)
        c["maxspd"] = max(c.get("maxspd", 0.0), spd)
        c["dist"] = haversine(c["home"][0], c["home"][1], lat, lon)
        c["arm_s"] = round(time.time() - c["t0"])
        if not TRACK2 or haversine(TRACK2[-1][0], TRACK2[-1][1], lat, lon) > 2.0:
            TRACK2.append([round(lat, 7), round(lon, 7), round(spd, 1)])
        if TEST.get("cars") == 2:                # car 1 ESP signal in the demo
            S["esp"] = {"rssi": -58 + random.randint(-2, 2), "pps": 18, "bad": 0, "t": time.time()}

def demo_thread(rows):
    """Plays the demo ride (speed 1x/2x/4x, pause, jump on the timeline), then 5 s disarmed, then again."""
    PLAY["len"] = rows[-1]["t"] if rows else 0.0
    cum = [0.0]
    for k in range(1, len(rows)):
        cum.append(cum[-1] + haversine(rows[k - 1]["lat"], rows[k - 1]["lon"], rows[k]["lat"], rows[k]["lon"]))
    while True:
        if not TEST["on"]:
            time.sleep(0.3); continue
        vt = 0.0; i = 0; last = time.time()
        with LOCK:
            set_mode("MANU")
        while TEST["on"] and i < len(rows):
            now = time.time()
            if not PLAY["pause"]:
                vt += (now - last) * PLAY["speed"]
            last = now
            sk = PLAY["seek"]
            if sk is not None:                     # jump: rebuild the track up to the new point without waiting
                PLAY["seek"] = None
                sk = max(0.0, min(PLAY["len"], float(sk)))
                with LOCK:
                    TRACK.clear(); S["trip"] = 0.0; S["maxspd"] = 0.0; MAH0["v"] = None
                car2_reset()
                i = 0; vt = sk
                while i < len(rows) and rows[i]["t"] < sk:
                    r = rows[i]
                    on_gps(r["lat"], r["lon"], r.get("kmh", 0.0), r.get("kurs", 0.0), int(r.get("alt", 268)), int(r.get("sats", 14)), "TEST")
                    car2_step(rows, cum, i, r["t"])
                    i += 1
                continue
            PLAY["t"] = vt
            r = rows[i]
            if r["t"] > vt:
                time.sleep(0.05); continue
            on_gps(r["lat"], r["lon"], r.get("kmh", 0.0), r.get("kurs", 0.0), int(r.get("alt", 268)), int(r.get("sats", 14)), "TEST")
            if "akkuV" in r:
                on_batt(round(r["akkuV"], 2), round(r.get("A", 0.0), 1), int(r.get("mAh", 0)), None, "TEST")
            if "lq" in r:
                on_link(int(r.get("dbm", -60)), int(r["lq"]), 8, 6, 3, "TEST")
            with LOCK:
                S["pitch"] = r.get("nick", 0.0); S["roll"] = r.get("roll", 0.0)
            car2_step(rows, cum, i, vt)
            if "t1" in r:                          # demo: Core line also from the demo ride, not from the real car
                CORE_LIVE["d"] = {"temps": [["ESC", round(r.get("t1", 0))], ["LED", round(r.get("t2", 0))], ["O4PRO", round(r.get("t3", 0))]],
                                  "pct": S.get("left"), "nr": None, "wet": False, "armed": True, "demo": True, "via": "demo", "name": "mojave"}
                CORE_LIVE["t"] = time.time()
            i += 1
        if not TEST["on"]:
            continue
        with LOCK:
            set_mode("OK")                       # disarmed at the end of the ride
            if C2:
                C2.update(mode="OK", armed=False, spd=0.0)
        for _ in range(50):
            if not TEST["on"]:
                break
            with LOCK:
                got_data("TEST")                 # pause at the end is not a lost link
            time.sleep(0.1)
        with LOCK:                               # next round starts at home again
            TRACK.clear(); S["trip"] = 0.0; S["maxspd"] = 0.0; MAH0["v"] = None
        car2_reset()
        PLAY["t"] = 0.0

def test_thread():
    rows = load_demo()
    if rows:
        return demo_thread(rows)
    t0 = time.time()
    lat0, lon0 = cf("test_lat"), cf("test_lon")
    lp = None
    while True:
        if not TEST["on"]:
            t0 = time.time(); lp = None
            time.sleep(0.3); continue
        t = time.time() - t0
        # lap: ellipse 330 x 190 m with a wobble, about 115 s per lap (max about 55 km/h)
        a = t * 2 * math.pi / 115.0
        rx, ry = 330.0, 190.0
        dx = rx * math.cos(a) + 25 * math.sin(3 * a)
        dy = ry * math.sin(a) + 15 * math.cos(2 * a)
        lat = lat0 + dy / 111320.0
        lon = lon0 + dx / (111320.0 * math.cos(math.radians(lat0)))
        if lp:
            d = haversine(lp[0], lp[1], lat, lon)
            spd = d / 0.1 * 3.6
            hdg = (math.degrees(math.atan2((lon - lp[1]) * math.cos(math.radians(lat)), lat - lp[0])) + 360) % 360
        else:
            spd, hdg = 0.0, 0.0
        lp = (lat, lon)
        sats = 14 if t > 2 else 4
        on_gps(lat, lon, spd, hdg, 268, sats, "TEST")
        v = max(21.0, 25.1 - t * 0.004) - spd * 0.006 + random.uniform(-0.03, 0.03)
        on_batt(round(v, 1), round(spd * 0.9, 1), int(t * 3), max(0, int(100 - t / 9)), "TEST")
        far = abs(math.cos(a))
        on_link(-int(55 + 40 * far + random.uniform(-3, 3)), int(100 - 25 * far * far), 8, 6, 3, "TEST")
        with LOCK:
            set_mode("MANU")
            S["pitch"] = round(4 * math.sin(t / 3.0), 1); S["roll"] = round(6 * math.sin(t / 2.1), 1)
        time.sleep(0.1)

# ---------------------------------------------------------------- tiles
ONLINE = {"down_until": 0.0}
FAIL = {}
FETCH_LOCK = threading.Lock()
INFLIGHT = {}

def tile_file(kind, z, x, y):
    return os.path.join(TILES, kind, str(z), str(x), "%d.jpg" % y)

DL_SEM = threading.Semaphore(6)   # max. parallel downloads

def _ipv4_only():
    """Only IPv4 for tile downloads (IPv6 not usable in many WLANs/hotspots)."""
    import socket
    orig = socket.getaddrinfo
    def gai(host, *a, **k):
        r = orig(host, *a, **k)
        v4 = [x for x in r if x[0] == socket.AF_INET]
        return v4 or r
    socket.getaddrinfo = gai

def fetch_online(z, x, y):
    """Download a tile into ortho cache. Returns bytes or None."""
    if CFG["online"] != "1" or z > ci("online_max_zoom"):
        return None
    if time.time() < ONLINE["down_until"]:
        return None
    key = (z, x, y)
    if FAIL.get(key, 0) > time.time():
        return None
    missing = 0
    with DL_SEM:
        for url in (CFG.get("online_url"), CFG.get("online_url2")):
            if not url:
                continue
            u = url.replace("{z}", str(z)).replace("{x}", str(x)).replace("{y}", str(y))
            try:
                rq = urllib.request.Request(u, headers={"User-Agent": "MojaveGroundStation/" + VERSION})
                with urllib.request.urlopen(rq, timeout=cf("online_timeout_s")) as r:
                    data = r.read()
                if len(data) < 100:
                    missing += 1
                    continue
                p = tile_file("ortho", z, x, y)
                os.makedirs(os.path.dirname(p), exist_ok=True)
                with open(p + ".tmp", "wb") as f:
                    f.write(data)
                os.replace(p + ".tmp", p)
                ONLINE["fails"] = 0
                return data
            except urllib.error.HTTPError:
                missing += 1      # tile does not exist on this server -> try next
                continue
            except Exception:
                continue          # slow/broken connection -> try next server
    if missing:
        FAIL[key] = time.time() + 300           # really missing: ask again in 5 min
    else:
        FAIL[key] = time.time() + 15            # network problem: retry this tile soon
        ONLINE["fails"] = ONLINE.get("fails", 0) + 1
        if ONLINE["fails"] >= 8:                # many in a row -> offline, pause briefly
            ONLINE["down_until"] = time.time() + 10
            ONLINE["fails"] = 0
    return None

DLQ = queue.Queue()
DL_WANT = set()

def dl_worker():
    while True:
        z, x, y = DLQ.get()
        try:
            fetch_online(z, x, y)
        except Exception:
            pass
        DL_WANT.discard((z, x, y))

KIC = {"t": 0.0, "d": None}

def ki_cover():
    """V2.0.17: which AI tiles exist (per zoom, per x column: list of y ranges). The page asks only for those,
    instead of trying every z20/z21 tile and getting 'missing' back (blue map bar on every replay)."""
    if KIC["d"] is not None and time.time() - KIC["t"] < 300:
        return KIC["d"]
    d = {}
    base = os.path.join(TILES, "ki")
    try:
        for zd in os.scandir(base):
            if not zd.is_dir() or not zd.name.isdigit():
                continue
            cols = {}
            for xd in os.scandir(zd.path):
                if not xd.is_dir() or not xd.name.isdigit():
                    continue
                ys = sorted(int(f.name[:-4]) for f in os.scandir(xd.path) if f.name.endswith(".jpg") and f.name[:-4].isdigit())
                runs = []
                for y in ys:
                    if runs and y == runs[-1][1] + 1:
                        runs[-1][1] = y
                    else:
                        runs.append([y, y])
                if runs:
                    cols[xd.name] = runs
            d[zd.name] = cols
    except Exception:
        pass
    KIC["d"], KIC["t"] = d, time.time()
    return d

def get_tile(z, x, y):
    """Tiles on the SD card come at once. Missing ones are downloaded in the background
    (the page asks again after a few seconds), so slow internet never blocks SD tiles."""
    for kind in ("ki", "ortho"):
        p = tile_file(kind, z, x, y)
        if os.path.exists(p):
            with open(p, "rb") as f:
                return f.read()
    key = (z, x, y)
    if (CFG["online"] == "1" and z <= ci("online_max_zoom") and key not in DL_WANT
            and FAIL.get(key, 0) <= time.time() and time.time() >= ONLINE["down_until"]):
        DL_WANT.add(key)
        DLQ.put(key)
    return None

def tiles_for(lat, lon, radius, z):
    n = 2 ** z
    def tx(lo): return (lo + 180.0) / 360.0 * n
    def ty(la):
        r = math.radians(la)
        return (1 - math.log(math.tan(r) + 1 / math.cos(r)) / math.pi) / 2 * n
    dlat = radius / 111320.0
    dlon = radius / (111320.0 * math.cos(math.radians(lat)))
    x0, x1 = int(tx(lon - dlon)), int(tx(lon + dlon))
    y0, y1 = int(ty(lat + dlat)), int(ty(lat - dlat))
    return [(z, x, y) for x in range(x0, x1 + 1) for y in range(y0, y1 + 1)]

PRE = {"running": False, "done": 0, "total": 0, "failed": 0, "skipped": 0, "cancel": False, "msg": ""}

# ---------------------------------------------------------------- USB stick import
# A stick with tiles (folders z/x/y.jpg, anywhere up to 3 levels deep) is copied to the SD card
# automatically when plugged in. Only tiles that are not on the SD card yet are copied.
# A folder named "ortho" goes to tiles/ortho, everything else to tiles/ki (AI tiles, shown first).
IMP = {"running": False, "done": 0, "total": 0, "copied": 0, "skipped": 0, "msg": "", "t": 0.0}
TILE_EXT = (".jpg", ".jpeg", ".png")

def _is_zoom_dir(d):
    try:
        n = os.path.basename(d)
        if not (n.isdigit() and 1 <= int(n) <= 23):
            return False
        for x in os.listdir(d):
            if x.isdigit() and os.path.isdir(os.path.join(d, x)):
                return True
    except Exception:
        pass
    return False

def find_tile_roots(base, depth=0):
    """Folders that contain zoom folders (z/x/y.jpg)."""
    roots = []
    try:
        subs = [os.path.join(base, x) for x in sorted(os.listdir(base)) if not x.startswith(".")]
    except Exception:
        return roots
    subs = [d for d in subs if os.path.isdir(d)]
    if any(_is_zoom_dir(d) for d in subs):
        return [base]
    if depth < 3:
        for d in subs:
            roots += find_tile_roots(d, depth + 1)
    return roots

def import_stick(mount):
    roots = find_tile_roots(mount)
    if not roots:
        IMP.update(running=False, done=0, total=0, copied=0, skipped=0, t=time.time(),
                   msg="USB stick %s: no map tiles found (folders z/x/y.jpg)" % os.path.basename(mount))
        return
    jobs = []
    for r in roots:
        kind = "ortho" if os.path.basename(r).lower() == "ortho" else "ki"
        for zd in os.listdir(r):
            zp = os.path.join(r, zd)
            if not _is_zoom_dir(zp):
                continue
            for xd in os.listdir(zp):
                xp = os.path.join(zp, xd)
                if not (xd.isdigit() and os.path.isdir(xp)):
                    continue
                for f in os.listdir(xp):
                    b, e = os.path.splitext(f)
                    if e.lower() in TILE_EXT and b.isdigit():
                        jobs.append((os.path.join(xp, f), tile_file(kind, int(zd), int(xd), int(b))))
    IMP.update(running=True, done=0, total=len(jobs), copied=0, skipped=0, msg="USB import", t=time.time())
    for src, dst in jobs:
        try:
            if os.path.exists(dst):
                IMP["skipped"] += 1
            else:
                os.makedirs(os.path.dirname(dst), exist_ok=True)
                shutil.copyfile(src, dst + ".tmp")
                os.replace(dst + ".tmp", dst)
                IMP["copied"] += 1
        except Exception:
            pass
        IMP["done"] += 1
    IMP.update(running=False, t=time.time(),
               msg="USB import done: %d new, %d already on SD card" % (IMP["copied"], IMP["skipped"]))

def usb_thread():
    seen = set()
    while True:
        bases = [CFG.get("usb_dir", "/media/" + os.environ.get("USER", "user1"))]
        mounts = set()
        for b in bases:
            try:
                for x in os.listdir(b):
                    if os.path.ismount(os.path.join(b, x)):
                        mounts.add(os.path.join(b, x))
            except Exception:
                pass
        for m in sorted(mounts - seen):
            if CFG.get("usb_import", "1") == "1":
                time.sleep(2)              # let the stick settle
                try:
                    import_stick(m)
                except Exception as ex:
                    IMP.update(running=False, msg="USB import error: %s" % ex, t=time.time())
        seen = mounts
        time.sleep(5)

def preload(lat, lon, radius, zmin, zmax):
    jobs = []
    for z in range(zmin, zmax + 1):
        jobs += tiles_for(lat, lon, radius, z)
    PRE.update(running=True, done=0, total=len(jobs), failed=0, skipped=0, cancel=False, msg="")
    q = queue.Queue()
    for j in jobs:
        q.put(j)

    def worker():
        while not PRE["cancel"]:
            try:
                z, x, y = q.get_nowait()
            except queue.Empty:
                return
            if os.path.exists(tile_file("ortho", z, x, y)) or os.path.exists(tile_file("ki", z, x, y)):
                PRE["skipped"] += 1
            else:
                ONLINE["down_until"] = 0
                if fetch_online(z, x, y) is None:
                    PRE["failed"] += 1
            PRE["done"] += 1

    ws = [threading.Thread(target=worker, daemon=True) for _ in range(4)]
    for w in ws: w.start()
    for w in ws: w.join()
    PRE["running"] = False
    PRE["msg"] = "Cancelled" if PRE["cancel"] else ("Done" if PRE["failed"] == 0 else "Done, %d tiles failed (offline?)" % PRE["failed"])

# ---------------------------------------------------------------- web server
WEB = os.path.join(BASE, "web")
TYPES = {".html": "text/html; charset=utf-8", ".js": "application/javascript", ".css": "text/css",
         ".png": "image/png", ".svg": "image/svg+xml", ".json": "application/json"}

class H(BaseHTTPRequestHandler):
    protocol_version = "HTTP/1.1"

    def log_message(self, *a):
        pass

    def send(self, code, body, ctype="application/json", cache=False):
        if isinstance(body, (dict, list)):
            body = json.dumps(body).encode()
        elif isinstance(body, str):
            body = body.encode()
        self.send_response(code)
        self.send_header("Content-Type", ctype)
        self.send_header("Content-Length", str(len(body)))
        self.send_header("Cache-Control", "max-age=86400" if cache else "no-store")
        self.end_headers()
        self.wfile.write(body)

    def body(self):
        n = int(self.headers.get("Content-Length") or 0)
        try:
            return json.loads(self.rfile.read(n) or b"{}")
        except Exception:
            return {}

    def do_GET(self):
        u = urlparse(self.path)
        p = u.path
        if p.startswith("/tile/"):
            try:
                z, x, y = [int(v.split(".")[0]) for v in p.split("/")[2:5]]
            except Exception:
                return self.send(400, {"err": "bad tile"})
            d = get_tile(z, x, y)
            return self.send(200, d, "image/jpeg", True) if d else self.send(404, b"", "text/plain")
        if p == "/api/update":                   # V2.0.26: state of the online update
            return self.send(200, {k: UPD[k] for k in ("busy", "prog", "msg", "online", "neu")} | {"cur": VERSION})
        if p == "/api/devices":                  # V2.0.22: IP addresses / host names of tracker, Core, Navi
            q = parse_qs(u.query)
            if not DEVS["busy"] and (q.get("new") or time.time() - DEVS["t"] > 15):
                DEVS["busy"], DEVS["prog"] = True, 1
                threading.Thread(target=devices_scan, daemon=True).start()
            return self.send(200, {"busy": DEVS["busy"], "prog": DEVS["prog"], "d": DEVS["d"]})
        if p == "/api/kicover":                  # V2.0.17
            return self.send(200, ki_cover())
        if p == "/api/rides":
            return self.send(200, {"rides": list_rides()})
        if p == "/api/wifi":                     # V1.8.3: saved Wi-Fi networks + switching state
            return self.send(200, {"list": wifi_list(), "scan": wifi_scan(), "busy": WIFI_SW["busy"], "msg": WIFI_SW["msg"], "target": WIFI_SW["target"],
                                   "secs": round(time.time() - WIFI_SW["t0"]) if WIFI_SW["t0"] else 0})
        if p == "/api/ride":
            name = os.path.basename(parse_qs(u.query).get("f", [""])[0])
            fn = os.path.join(BASE, "logs", name)
            if not name.endswith(".csv") or not os.path.exists(fn):
                return self.send(404, {"err": "no ride"})
            r = ride_stats(fn, True)
            r["win"] = (r.get("t0") or 0, r.get("t1") or 0)   # V2.0.15: time window of the chosen ride (pieces are cut to it)
            others = []                          # V2.0.5: the other vehicle(s) driving/flying at the same time
            for x in ride_files():
                if x["name"] != name and ride_overlap({"t0": r["win"][0], "t1": r["win"][1]}, x, 30):
                    o = ride_stats(os.path.join(BASE, "logs", x["name"]), True)
                    if not o.get("pts"):
                        continue
                    if same_veh(r, o):           # V2.0.13: piece of the same model (slot change, restart) -> one track
                        ride_merge(r, o)
                        continue
                    o["win"] = r["win"]
                    w0, w1 = r["win"]                # V2.0.15: other vehicles also only at the time of this ride
                    o["pts"] = [q for q in o["pts"] if w0 - 60 <= q[4] <= w1 + 60]
                    if not o["pts"]:
                        continue
                    if o["pts"][0][6]:
                        o["pts"][0][6] = 0
                    for q in others:
                        if same_veh(q, o):
                            ride_merge(q, o)
                            break
                    else:
                        others.append(o)
            for q in [r] + others:
                q.pop("win", None)
            r["others"] = others
            return self.send(200, r)
        if p == "/api/state":
            return self.send(200, snapshot())
        if p == "/api/senders":                  # V2.0: heard + known senders for the menu
            with LOCK:
                return self.send(200, {"list": senders_list(), "auto": CFG.get("sender_auto", "1") == "1", "cols": SND_COLS})
        if p == "/api/track":
            f = int(parse_qs(u.query).get("from", ["0"])[0])
            cn = int(parse_qs(u.query).get("car", ["1"])[0] or 1)
            tr = TRK.get(cn, TRACK) if cn >= 2 else TRACK
            with LOCK:
                return self.send(200, {"from": f, "pts": tr[f:f + 5000], "len": len(tr)})
        if p == "/api/cfgdesc":                   # V1.9.16: all settings with description for the settings editor
            return self.send(200, {"items": [{"k": k, "v": CFG.get(k, ""), "d": d, "c": c} for k, d, c in DEFAULTS]})
        if p == "/api/config":
            c = {k: CFG[k] for k, _, _ in DEFAULTS}
            c["win"] = WIN                          # V2.0.27: page hides Pi-only parts (Wi-Fi, brightness, start menu)
            du = shutil.disk_usage(BASE)
            c["free_mb"] = du.free // 1048576
            c["total_mb"] = du.total // 1048576       # V1.9.13: SD card size for the menu
            c["version"] = VERSION
            return self.send(200, c)
        if p == "/api/preload":
            return self.send(200, PRE)
        if p == "/" or p == "/index.html":
            p = "/index.html"
        fp = os.path.normpath(os.path.join(WEB, p.lstrip("/")))
        if fp.startswith(WEB) and os.path.isfile(fp):
            with open(fp, "rb") as f:
                return self.send(200, f.read(), TYPES.get(os.path.splitext(fp)[1], "application/octet-stream"))
        self.send(404, {"err": "not found"})

    def do_POST(self):
        global TRACK
        p = urlparse(self.path).path
        b = self.body()
        if p == "/api/launch":                  # V2.0.3: start menu -> other program (only one big program at a time, 1 GB RAM)
            app = str(b.get("app", ""))
            if app == "desktop":
                def _desk():
                    try:                     # V2.0.4: finger works as a mouse on the desktop (tracker keeps real touch)
                        subprocess.run(["bash", os.path.join(BASE, "touchmode.sh"), "mouse"], timeout=10)
                    except Exception as e:
                        print("touchmode failed", e)
                    try:
                        subprocess.Popen(["/usr/bin/lwrespawn", "/usr/bin/pcmanfm-pi"], start_new_session=True,
                                         stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
                    except Exception as e:
                        print("desktop start failed", e)
                    time.sleep(1.5)
                    subprocess.run(["pkill", "-f", "chromium"], stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
                threading.Thread(target=_desk, daemon=True).start()
                return self.send(200, {"ok": True})
            return self.send(400, {"err": "unknown app"})
        if p == "/api/sender":                  # V2.0: change / forget a sender, or switch automatic assignment
            with LOCK:
                if "auto" in b:
                    CFG["sender_auto"] = "1" if b["auto"] else "0"
                    save_cfg(CFG)
                    return self.send(200, {"ok": True})
                mac = str(b.get("mac", "")).upper()
                if not re.fullmatch(r"[0-9A-F]{2}(:[0-9A-F]{2}){5}", mac):
                    return self.send(400, {"err": "bad mac"})
                if b.get("forget"):
                    SND.pop(mac, None); SEEN.pop(mac, None)
                    save_senders()
                    return self.send(200, {"ok": True})
                x = SND.get(mac) or {"slot": 0, "type": "car", "sym": 1, "col": SND_COLS[0], "name": "", "pilot": ""}
                if "slot" in b:
                    x["slot"] = max(0, min(2, int(b["slot"])))   # V2.0.6: 1 = prefers the main view, 2 = shown, 0 = hidden
                    if x["slot"] == 1:
                        for m, o in SND.items():
                            if m != mac and o["slot"] == 1:
                                o["slot"] = 2
                    if x["slot"] == 0:
                        for n2 in [n2 for n2, a in ACT.items() if a["mac"] == mac]:
                            del ACT[n2]
                if b.get("type") in ("car", "plane"):
                    x["type"] = b["type"]
                if "sym" in b:
                    x["sym"] = max(0, min(2, int(b["sym"])))
                if isinstance(b.get("col"), str) and re.fullmatch(r"#?[0-9a-fA-F]{6}", b["col"]):
                    x["col"] = b["col"].lstrip("#").lower()
                if isinstance(b.get("name"), str):
                    x["name"] = re.sub(r"[/;#,=\n\r]", "", b["name"]).strip()[:14]
                if isinstance(b.get("pilot"), str):     # V2.0.5: pilot / driver of this radio
                    x["pilot"] = re.sub(r"[/;#,=\n\r]", "", b["pilot"]).strip()[:14]
                    log_names()
                SND[mac] = x
                save_senders()
                return self.send(200, {"ok": True, "s": dict(x, mac=mac)})
        if p == "/api/set":                     # small settings from the menu (saved in config.txt)
            ok = {}
            if b.get("orientation") in ("north", "heading"):   # V1.8.2: menu settings survive a restart (browser runs incognito)
                CFG["orientation"] = b["orientation"]; ok["orientation"] = b["orientation"]
            for k in ("bright", "sound", "range_warn_m", "core_show", "night", "auto_zoom", "map_names"):
                if k in b:
                    v = str(int(float(b[k])))
                    CFG[k] = v
                    ok[k] = v
                    if k == "bright":
                        set_bright(int(v))
            if isinstance(b.get("names"), str) and re.fullmatch(r"[^,;=#\n\r]{0,14},[^,;=#\n\r]{0,14}", b["names"]):   # V1.9.4
                CFG["names"] = b["names"].strip(); ok["names"] = CFG["names"]
                try:
                    log_names()
                except Exception:
                    pass
            if "auto_zoom_out" in b:                 # V1.9.6: auto zoom strength from the menu (- / +)
                try:
                    v = max(0.0, min(3.0, round(float(b["auto_zoom_out"]), 1)))
                    CFG["auto_zoom_out"] = str(v); ok["auto_zoom_out"] = v
                except Exception:
                    pass
            if isinstance(b.get("icons"), str) and re.fullmatch(r"[0-9-]{10}\|[0-9:,]{0,40}", b["icons"]):   # V1.9 map symbols
                CFG["icons"] = b["icons"]; ok["icons"] = b["icons"]
            if ok:
                save_cfg(CFG)
            return self.send(200, ok)
        if p == "/api/ridedel":                   # V2.0.18: delete marked rides = move them to logs/geloescht (can be brought back)
            lg = os.path.join(BASE, "logs")
            trash = os.path.join(lg, "geloescht")
            os.makedirs(trash, exist_ok=True)
            n = 0
            for name in b.get("names") or []:
                name = os.path.basename(str(name))
                fn = os.path.join(lg, name)
                if not name.endswith(".csv") or not os.path.isfile(fn):
                    continue
                if time.time() - os.path.getmtime(fn) < 30:   # still being written (vehicle is live)
                    continue
                os.replace(fn, os.path.join(trash, name))
                n += 1
            return self.send(200, {"ok": True, "n": n})
        if p == "/api/cfgset":                    # V1.9.16: settings editor - one key
            k, v = str(b.get("k", "")), str(b.get("v", ""))
            if k not in {x for x, _, _ in DEFAULTS} or len(v) > 400 or any(ch in v for ch in "#\n\r"):
                return self.send(400, {"err": "not allowed"})
            CFG[k] = v.strip()
            save_cfg(CFG)
            return self.send(200, {"ok": True, "k": k, "v": CFG[k]})
        if p == "/api/update":                    # V2.0.26: {check:1} or {install:1}
            if b.get("install") and not UPD["busy"]:
                threading.Thread(target=upd_install, daemon=True).start()
            elif b.get("check") and not UPD["busy"]:
                upd_check()
            return self.send(200, {k: UPD[k] for k in ("busy", "prog", "msg", "online", "neu")} | {"cur": VERSION})
        if p == "/api/restart":                   # V1.9.16: restart the program so config.txt is read again
            def _re():
                time.sleep(0.6)
                os.execv(sys.executable, [sys.executable] + sys.argv)
            threading.Thread(target=_re, daemon=True).start()
            return self.send(200, {"ok": True})
        if p == "/api/wifi":
            if b.get("rescan"):
                threading.Thread(target=lambda: nm("dev", "wifi", "rescan", timeout=8), daemon=True).start()
                return self.send(200, {"ok": True})
            if b.get("ssid"):                    # V2.0.13: add a new network (password from the on-screen keyboard)
                if WIFI_SW["busy"]:
                    return self.send(200, {"ok": False})
                threading.Thread(target=wifi_add, args=(str(b["ssid"])[:32], str(b.get("psk", ""))[:63]), daemon=True).start()
                return self.send(200, {"ok": True})
            con = str(b.get("con", ""))
            nets = {w["con"]: w["ssid"] for w in wifi_list()}
            if WIFI_SW["busy"] or con not in nets:
                return self.send(200, {"ok": False})
            threading.Thread(target=wifi_switch, args=(con, nets[con]), daemon=True).start()
            return self.send(200, {"ok": True})
        if p == "/api/play":                     # V1.8.1: {"speed": 1|2|4, "pause": bool, "seek": seconds}
            if "speed" in b:
                PLAY["speed"] = float(b["speed"]) if float(b["speed"]) in (1.0, 2.0, 4.0) else 1.0
            if "pause" in b:
                PLAY["pause"] = bool(b["pause"])
            if "seek" in b:
                PLAY["seek"] = float(b["seek"])
            return self.send(200, {"speed": PLAY["speed"], "pause": PLAY["pause"]})
        if p == "/api/test":
            TEST["on"] = bool(b.get("on"))
            TEST["cars"] = 2 if b.get("cars") == 2 else 1
            car2_reset()
            PLAY["pause"] = False; PLAY["seek"] = None; PLAY["t"] = 0.0
            with LOCK:
                TRACK = []
                S.update(home=None, alt0=None, dist=None, maxspd=0.0, lat=None, lon=None, trip=0.0)
            if LOG["f"]:
                LOG["f"].close(); LOG["f"] = None
            if LOG2["f"]:
                LOG2["f"].close(); LOG2["f"] = None
            return self.send(200, {"test": TEST["on"]})
        if p == "/api/home":
            with LOCK:
                if S["lat"] is not None:
                    S["home"] = [S["lat"], S["lon"]]; S["dist"] = 0.0; S["alt0"] = S.get("alt")
            return self.send(200, {"ok": 1})
        if p == "/api/clear":
            with LOCK:
                TRACK = []; S["maxspd"] = 0.0; S["trip"] = 0.0; MAH0["v"] = None; S["mah_used"] = 0
            return self.send(200, {"ok": 1})
        if p == "/api/preload":
            if b.get("cancel"):
                PRE["cancel"] = True
                return self.send(200, PRE)
            if PRE["running"]:
                return self.send(409, PRE)
            try:
                lat, lon = float(b["lat"]), float(b["lon"])
                r = max(100, min(20000, float(b.get("radius", cf("preload_radius_m")))))
                z0 = max(1, int(b.get("zmin", ci("preload_zmin"))))
                z1 = min(ci("online_max_zoom"), int(b.get("zmax", ci("preload_zmax"))))
            except Exception:
                return self.send(400, {"err": "bad request"})
            n = sum(len(tiles_for(lat, lon, r, z)) for z in range(z0, z1 + 1))
            if n > 60000:
                return self.send(400, {"err": "too many tiles (%d)" % n})
            threading.Thread(target=preload, args=(lat, lon, r, z0, z1), daemon=True).start()
            return self.send(200, {"total": n})
        self.send(404, {"err": "not found"})

def main():
    if CFG.get("ipv4_only", "1") == "1":
        _ipv4_only()
    threading.Thread(target=serial_thread, daemon=True).start()
    threading.Thread(target=test_thread, daemon=True).start()
    if not WIN:
        threading.Thread(target=wifi_thread, daemon=True).start()
    threading.Thread(target=core_thread, daemon=True).start()
    threading.Thread(target=upd_thread, daemon=True).start()
    for _ in range(6):
        threading.Thread(target=dl_worker, daemon=True).start()
    threading.Thread(target=core_live_thread, daemon=True).start()
    if not WIN:
        set_bright(ci("bright"))
        threading.Thread(target=usb_thread, daemon=True).start()
    port = ci("port")
    srv = ThreadingHTTPServer(("0.0.0.0", port), H)
    srv.daemon_threads = True
    print("Mojave Ground Station V%s on http://localhost:%d" % (VERSION, port))
    srv.serve_forever()

if __name__ == "__main__":
    main()
