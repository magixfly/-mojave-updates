# ThermoGrip – Firmware V4.2 (22.11.2026)
# Raspberry Pi Pico 2 W + Waveshare Pico-LCD-1.3 (240x240, Joystick, A/B/X/Y)
# MicroPython. Settings in config.txt, fonts in fonts.bin (Inter, 4 bit).
# Without a battery (USB only) no watchdog runs -> editing with Viper/Thonny always possible.
# Maintenance mode: hold button B at power-up -> program does not start.

import time, framebuf, gc, math, struct
from array import array
from machine import Pin, SPI, PWM, ADC, WDT

VERSION = "V8.8"

# ---------------------------------------------------------------- Pins
P_DC, P_CS, P_SCK, P_MOSI, P_RST, P_BL = 8, 9, 10, 11, 12, 13
KEYS = {"A": 15, "B": 17, "X": 19, "Y": 21, "UP": 2, "DOWN": 18, "LEFT": 16, "RIGHT": 20, "CTRL": 3}
P_HEIZ, P_LUEFTER = 22, 7
P_NTC_FOLIE, P_NTC_HAND, P_AKKU = 26, 27, 28

# ---------------------------------------------------------------- config.txt
DEFAULT_CFG = """# ThermoGrip - settings (lines starting with # are comments)
# Restart the Pico after saving.

target_temp_start = 36    # target temperature at power-up in deg C
remember_target   = 1     # 1 = start with the last target you set (saved in last_target.txt), 0 = always target_temp_start
target_temp_min   = 30    # lowest selectable temperature
target_temp_max   = 42    # highest selectable temperature (max 45)
pad_temp_max      = 60    # heating pad must never get hotter (max 60)
pad_temp_hold     = 50    # pad limit once the hand temperature has reached the target (0 = off)
pad_full_below    = 5     # hand this many deg C (or more) below target -> full pad_temp_max; closer to target it slides down to pad_temp_hold
pad_over_target   = 0     # pad may be this much warmer than the target (0 = only pad_temp_max limits)
no_hand_offset    = 18    # without hand sensor: pad is held at target + this (max pad_temp_max), e.g. 42 + 18 = 60
boost_minutes     = 5     # button Y: this long at target_temp_max

power_auto        = 1     # 1 = limit power by battery voltage so the 12 V pads never get more than their rated power
pad_volts         = 14    # voltage used for the power limit (pads are 12 V; 14 = approx. 16 W per pad on a full 4S)
power_3s_max      = 100   # fixed limit in percent on 3S (only if power_auto = 0)
power_4s_max      = 50    # fixed limit in percent on 4S (only if power_auto = 0)
battery_cells     = 0     # 0 = detect automatically, 3 or 4 = fixed
demo_on_usb       = 1     # 1 = USB only (no battery): demo mode with simulated values, heater stays off
auto_off_minutes  = 15    # switch off after this many minutes in standby (0 = never)
key_lock_seconds  = 60    # lock buttons after this many seconds without input (0 = never); unlock: press A 3x
heater_check_minutes = 3  # alarm if heating hard this long but pad gets < heater_check_rise warmer (0 = off)
heater_check_rise = 2     # minimum pad temperature rise in deg C during that time
wifi_enable       = 1     # 1 = connect to WiFi; web page for settings + firmware update
wifi_ssid         =       # WiFi 1 (the one with the best signal is used)
wifi_pass         =
wifi_ssid2        =       # WiFi 2 (optional)
wifi_pass2        =
wifi_ssid3        =       # WiFi 3 (optional)
wifi_pass3        =
wifi_ssid4        =       # WiFi 4 (optional)
wifi_pass4        =
update_url        = https://raw.githubusercontent.com/magixfly/-mojave-updates/main/thermogrip/  # where version.json + files are (GitHub or http://PC-IP:8000/)
update_auto       = 1     # 1 = install a newer version automatically when the heater is off, 0 = only via web page
update_check_hours = 6    # check for updates every this many hours
power_off_pin     = 6     # GPIO to the OFF input of a Pololu pushbutton power switch (-1 = none)
beeper_pin        = 4     # GPIO for the buzzer (-1 = none)
beeper_type       = 2     # 2 = small passive piezo directly on the pin, 0 = active buzzer via MOSFET module, 1 = servo-PWM beeper
beeper_hz         = 2700  # tone for the passive piezo (loudest around 2000-4000 Hz)
beeper_on_us      = 2000  # servo pulse that switches the beeper on (microseconds)
beeper_off_us     = 1000  # servo pulse that keeps the beeper silent
heater_watts_12v  = 24    # total power of all pads at 12 V (2 x 12 W = 24)

fan_percent       = 20    # fan speed at power-up
fan_auto          = 1     # 1 = fan only runs while heating

battery_liion     = 1     # 0 = LiPo, 1 = Li-Ion (18650/21700): other % curve, off 3.3 V per cell
warn_cell_volts   = 3.6   # warning below this cell voltage: beep 2x, then 1 min pause
off_cell_volts    = 3.5   # heater off below this cell voltage (Li-Ion uses 3.3 automatically)
battery_mah       = 2200  # battery capacity for the runtime estimate
battery_calibration = 1.000 # factor if the battery voltage reads wrong

ntc_beta          = 3950  # NTC B value
temp_smooth_s     = 4     # smoothing of the temperature display in seconds (higher = calmer, slower)
battery_smooth_s  = 20    # smoothing of battery % and runtime in seconds (voltage drops while heating)
brightness        = 80    # display brightness in percent
display_rotate    = 0     # 0 or 180
control_kp        = 25    # controller: percent per degree of error
control_ki        = 0.5   # controller: integral gain per second
"""

def load_cfg():
    try:
        open("config.txt").close()
    except OSError:
        with open("config.txt", "w") as f:
            f.write(DEFAULT_CFG)
    try:                                                    # V4.10: alte Standardzeile (50 °C) einmalig auf 60 °C anheben
        t = open("config.txt").read()
        if "pad_temp_max      = 50    # heating pad must never get hotter (max 55)" in t:
            with open("config.txt", "w") as fh:
                fh.write(t.replace("pad_temp_max      = 50    # heating pad must never get hotter (max 55)", "pad_temp_max      = 60    # heating pad must never get hotter (max 60)"))
        t = open("config.txt").read()                       # V5.4: Tastensperre 10 s -> 60 s, Entsperren 3x A
        old = "key_lock_seconds  = 10    # lock buttons after this many seconds without input (0 = never); unlock: hold A + Y 2 s"
        if old in t:
            with open("config.txt", "w") as fh:
                fh.write(t.replace(old, "key_lock_seconds  = 60    # lock buttons after this many seconds without input (0 = never); unlock: press A 3x"))
        try:                                                # V6.8: WLAN-Daten aus wifi.txt (nur vom USB-Updater) uebernehmen
            w = open("wifi.txt").read()
            vals = {}
            for l in w.split("\n"):
                if "=" in l:
                    k, v = l.split("=", 1)
                    vals[k.strip()] = v.strip()
            lines = open("config.txt").read().split("\n"); have = set()
            for i, l in enumerate(lines):
                k = l.split("=")[0].strip()
                if "=" in l and k in vals and not l.strip().startswith("#"):
                    lines[i] = "%-17s = %s" % (k, vals[k]); have.add(k)
            for k in vals:
                if k not in have:
                    lines.append("%-17s = %s" % (k, vals[k]))
            with open("config.txt", "w") as fh:
                fh.write("\n".join(lines))
            import os
            os.remove("wifi.txt")
        except OSError:
            pass
        t = open("config.txt").read()                       # V5.6: neue Zeile remember_target ergaenzen
        if "pad_volts         = 12    # rated voltage of the heating pads (power_auto)" in t:                       # V6.3: pad_volts 12 -> 14
            t = t.replace("pad_volts         = 12    # rated voltage of the heating pads (power_auto)", "pad_volts         = 14    # voltage used for the power limit (pads are 12 V; 14 = approx. 16 W per pad on a full 4S)")
            with open("config.txt", "w") as fh:
                fh.write(t)
        if "update_url" not in t:                            # V6.5: mehrere WLANs + Update aus dem Internet
            new = ["wifi_ssid2        =       # WiFi 2 (optional)", "wifi_pass2        =",
                   "wifi_ssid3        =       # WiFi 3 (optional)", "wifi_pass3        =",
                   "wifi_ssid4        =       # WiFi 4 (optional)", "wifi_pass4        =",
                   "update_url        = https://raw.githubusercontent.com/magixfly/-mojave-updates/main/thermogrip/  # where version.json + files are (GitHub or http://PC-IP:8000/)",
                   "update_auto       = 1     # 1 = install a newer version automatically when the heater is off, 0 = only via web page",
                   "update_check_hours = 6    # check for updates every this many hours"]
            lines = t.split("\n"); pos = len(lines)
            for i, l in enumerate(lines):
                if l.startswith("wifi_pass"): pos = i + 1
            lines[pos:pos] = new
            t = "\n".join(lines)
            with open("config.txt", "w") as fh:
                fh.write(t)
        lines = t.split("\n"); chg = False                   # V8.2: pad_full_below 10 -> 5 (volle Mattengrenze bis 5 grad unter Ziel)
        for i, l in enumerate(lines):
            if l.startswith("pad_full_below") and l.split("#")[0].split("=")[1].strip() == "10":
                lines[i] = "pad_full_below    = 5     # hand this many deg C (or more) below target -> full pad_temp_max; closer to target it slides down to pad_temp_hold"; chg = True
        if chg:
            t = "\n".join(lines)
            with open("config.txt", "w") as fh:
                fh.write(t)
        if "no_hand_offset" not in t:
            lines = t.split("\n"); pos = len(lines)
            for i, l in enumerate(lines):
                if l.startswith("pad_over_target"): pos = i + 1
            lines.insert(pos, "no_hand_offset    = 18    # without hand sensor: pad is held at target + this (max pad_temp_max), e.g. 42 + 18 = 60")
            t = "\n".join(lines)
            with open("config.txt", "w") as fh:
                fh.write(t)
        if "remember_target" not in t:
            line = "remember_target   = 1     # 1 = start with the last target you set (saved in last_target.txt), 0 = always target_temp_start"
            lines = t.split("\n"); pos = len(lines)
            for i, l in enumerate(lines):
                if l.startswith("target_temp_start"): pos = i + 1
            lines.insert(pos, line)
            with open("config.txt", "w") as fh:
                fh.write("\n".join(lines))
        lines = open("config.txt").read().split("\n")         # V7.0: alle fehlenden Einstellungen ergaenzen (fuer Webseite)
        have = set(l.split("=")[0].strip() for l in lines if "=" in l and not l.strip().startswith("#"))
        add, prev = False, None
        for dl in DEFAULT_CFG.split("\n"):
            if "=" not in dl or dl.strip().startswith("#"):
                continue
            k = dl.split("=")[0].strip()
            if k not in have:
                pos = len(lines)
                if prev is not None:
                    for i, l in enumerate(lines):
                        if "=" in l and l.split("=")[0].strip() == prev:
                            pos = i + 1
                lines.insert(pos, dl); have.add(k); add = True
            prev = k
        if add:
            with open("config.txt", "w") as fh:
                fh.write("\n".join(lines))
    except OSError:
        pass
    cfg = {}
    for txt in (DEFAULT_CFG, open("config.txt").read()):
        for line in txt.split("\n"):
            line = line.split("#")[0].strip()
            if "=" in line:
                k, v = [s.strip() for s in line.split("=", 1)]
                try:
                    cfg[k] = float(v)
                except ValueError:
                    cfg[k] = v                                  # Text (z. B. WLAN-Name)
    cfg["target_temp_max"] = min(cfg["target_temp_max"], 45)
    cfg["pad_temp_max"] = min(cfg["pad_temp_max"], 75)          # V7.8: neue Pads bis 75 erlaubt
    cfg["pad_temp_hold"] = min(cfg["pad_temp_hold"], cfg["pad_temp_max"])   # V7.7: hold nie ueber max
    global SOC
    if cfg.get("battery_liion", 0) == 1:
        SOC = SOC_LIION
        if cfg["off_cell_volts"] == 3.5: cfg["off_cell_volts"] = 3.3
    cfg["target_temp_min"] = max(20, min(cfg["target_temp_min"], cfg["target_temp_max"]))
    return cfg

# ---------------------------------------------------------------- Farben
def c565(r, g, b):
    c = ((r & 0xF8) << 8) | ((g & 0xFC) << 3) | (b >> 3)
    return ((c & 0xFF) << 8) | (c >> 8)          # Byte-Reihenfolge fuer SPI

def mix(a, b, t):
    return tuple(int(a[i] + (b[i] - a[i]) * t) for i in range(3))

BG_TOP, BG_BOT = (18, 34, 68), (6, 12, 28)
CARD = (22, 40, 74)
WHITE, MUTED = (240, 244, 250), (178, 198, 232)
ORANGE, RED = (255, 140, 40), (236, 70, 70)
TEAL, GREEN, BLUE = (40, 200, 190), (70, 205, 120), (90, 150, 255)
RING_OFF = (38, 56, 92)

# ---------------------------------------------------------------- Schriften
class Font:
    def __init__(self, mv, pos):
        name, self.h, self.asc, n = struct.unpack_from("<8sBBH", mv, pos); pos += 12
        self.g = {}
        for i in range(n):
            cp, w, adv, lb, off = struct.unpack_from("<HBBbI", mv, pos); pos += 9
            self.g[cp] = (w, adv, lb, off)
        size = struct.unpack_from("<I", mv, pos)[0]; pos += 4
        self.mv = mv[pos:pos + size]; self.end = pos + size
        self.name = name.rstrip(b"\0").decode()
    def width(self, s):
        return sum(self.g.get(ord(c), self.g[32])[1] for c in s)
    def draw(self, fb, s, x, y, fg, bg, align=0):     # align: 0 links, 1 mitte, 2 rechts
        if align:
            x -= self.width(s) // (2 if align == 1 else 1)
        pal = palette(fg, bg)
        key = c565(*bg)
        for c in s:
            w, adv, lb, off = self.g.get(ord(c), self.g[32])
            if w:
                w2 = w + (w & 1)
                gb = framebuf.FrameBuffer(self.mv[off:off + w2 * self.h // 2], w2, self.h, framebuf.GS4_HMSB)
                fb.blit(gb, x + lb, y, key, pal)
            x += adv
        return x

_pal = {}
def palette(fg, bg):
    k = (fg, bg)
    p = _pal.get(k)
    if p is None:
        if len(_pal) > 40:
            _pal.clear()
        b = bytearray(32); p = framebuf.FrameBuffer(b, 16, 1, framebuf.RGB565)
        for i in range(16):
            p.pixel(i, 0, c565(*mix(bg, fg, i / 15)))
        _pal[k] = p
    return p

def load_fonts():
    import os
    gc.collect()
    data = bytearray(os.stat("fonts.bin")[6])
    with open("fonts.bin", "rb") as fh:
        fh.readinto(data)                                   # ohne zweite Kopie im RAM
    mv = memoryview(data); n = data[4]; pos = 5; fonts = {}
    for _ in range(n):
        f = Font(mv, pos); fonts[f.name] = f; pos = f.end
    return fonts

# ---------------------------------------------------------------- Display ST7789
class LCD(framebuf.FrameBuffer):
    W = H = 240
    def __init__(self, rot=0, bright=80):
        self.buf = bytearray(self.W * self.H * 2)
        super().__init__(self.buf, self.W, self.H, framebuf.RGB565)
        self.bgc = [c565(*bgcol(y)) for y in range(self.H)]    # Verlauf als Farbliste (spart 115 KB RAM)
        self.spi = SPI(1, 62_500_000, polarity=0, phase=0, sck=Pin(P_SCK), mosi=Pin(P_MOSI))
        self.dc, self.cs, self.rst = Pin(P_DC, Pin.OUT), Pin(P_CS, Pin.OUT, value=1), Pin(P_RST, Pin.OUT, value=1)
        self.bl = PWM(Pin(P_BL)); self.bl.freq(1000); self.light(bright)
        self.rst(0); time.sleep_ms(20); self.rst(1); time.sleep_ms(120)
        mad = 0x70 if rot == 0 else 0xA0
        for c, d in ((0x36, [mad]), (0x3A, [0x05]), (0xB2, [0x0C, 0x0C, 0x00, 0x33, 0x33]), (0xB7, [0x35]),
                     (0xBB, [0x19]), (0xC0, [0x2C]), (0xC2, [0x01]), (0xC3, [0x12]), (0xC4, [0x20]),
                     (0xC6, [0x0F]), (0xD0, [0xA4, 0xA1]),
                     (0xE0, [0xD0, 0x04, 0x0D, 0x11, 0x13, 0x2B, 0x3F, 0x54, 0x4C, 0x18, 0x0D, 0x0B, 0x1F, 0x23]),
                     (0xE1, [0xD0, 0x04, 0x0C, 0x11, 0x13, 0x2C, 0x3F, 0x44, 0x51, 0x2F, 0x1F, 0x1F, 0x20, 0x23]),
                     (0x21, []), (0x11, None), (0x29, [])):
            self.cmd(c, d)
            if d is None:
                time.sleep_ms(120)
    def light(self, pct):
        self.bl.duty_u16(int(max(5, min(100, pct)) * 655.35))
    def cmd(self, c, data=None):
        self.cs(0); self.dc(0); self.spi.write(bytes([c]))
        if data:
            self.dc(1); self.spi.write(bytes(data))
        self.cs(1)
    def clear(self):
        fr = self.fill_rect; c = self.bgc
        for y in range(0, self.H, 2):
            fr(0, y, self.W, 2, c[y])
    def show(self):
        if LOCKUI["on"] and LOCKUI["f"]:
            lock_icon(self, 119, 6)
            if LOCKUI["hint"]:
                rrect(self, 16, 92, 208, 56, 12, (10, 18, 36))
                LOCKUI["f"]["small"].draw(self, LOCKUI["hint"], 120, 98, WHITE, (10, 18, 36), 1)
                LOCKUI["f"]["small"].draw(self, "press A 3x", 120, 120, MUTED, (10, 18, 36), 1)
        self.cmd(0x2A, [0, 0, 0, 239]); self.cmd(0x2B, [0, 0, 0, 239])
        self.cs(0); self.dc(0); self.spi.write(b"\x2C"); self.dc(1); self.spi.write(self.buf); self.cs(1)

ST = {"version": VERSION}            # Status fuer die Webseite
try:                                     # V8.8: MicroPython-Version fuer Diagnose
    import sys as _sys
    ST["mpy"] = "%s / mpy %s" % (".".join(str(x) for x in _sys.implementation.version[:3]), getattr(_sys.implementation, "_mpy", "?"))
except Exception:
    pass
LOCKUI = {"on": False, "hint": "", "f": None}
def lock_icon(fb, x, y):
    c = c565(*ORANGE)
    fb.fill_rect(x, y + 7, 14, 10, c)                       # Schlosskoerper
    fb.rect(x + 3, y, 8, 9, c); fb.rect(x + 4, y + 1, 6, 8, c)   # Buegel
    fb.fill_rect(x + 6, y + 10, 2, 4, c565(10, 18, 36))     # Schluesselloch

def bgcol(y):
    return mix(BG_TOP, BG_BOT, y / 239)

# ---------------------------------------------------------------- Zeichenhilfen
def rrect(fb, x, y, w, h, r, col):
    c = c565(*col)
    fb.fill_rect(x + r, y, w - 2 * r, h, c); fb.fill_rect(x, y + r, w, h - 2 * r, c)
    fb.ellipse(x + r, y + r, r, r, c, True, 2); fb.ellipse(x + w - r - 1, y + r, r, r, c, True, 1)
    fb.ellipse(x + r, y + h - r - 1, r, r, c, True, 4); fb.ellipse(x + w - r - 1, y + h - r - 1, r, r, c, True, 8)

RING = []
def ring_init(cx, cy, r1, r2, n=36):
    RING.clear()
    for i in range(n):
        a0 = math.radians(135 + 270 * i / n + 1.2); a1 = math.radians(135 + 270 * (i + 1) / n - 1.2)
        pts = []
        for a, r in ((a0, r2), (a1, r2), (a1, r1), (a0, r1)):
            pts += [int(cx + r * math.cos(a)), int(cy + r * math.sin(a))]
        RING.append(array("h", pts))

def ring(fb, pct):
    n = len(RING); on = int(round(n * max(0, min(100, pct)) / 100))
    for i, p in enumerate(RING):
        col = mix((255, 180, 50), (240, 60, 40), i / n) if i < on else RING_OFF
        fb.poly(0, 0, p, c565(*col), True)

def icon(fb, kind, cx, cy, col):
    c = c565(*col)
    if kind == "fan":
        for dx, dy in ((0, -5), (5, 3), (-5, 3)):
            fb.ellipse(cx + dx, cy + dy, 3, 4 if dy < 0 else 3, c, True)
        fb.ellipse(cx, cy, 2, 2, c565(*CARD), True)
    elif kind == "bat":
        fb.rect(cx - 8, cy - 5, 15, 10, c); fb.fill_rect(cx + 7, cy - 2, 2, 4, c); fb.fill_rect(cx - 6, cy - 3, 9, 6, c)
    elif kind == "temp":
        fb.fill_rect(cx - 2, cy - 8, 4, 10, c); fb.ellipse(cx, cy + 4, 4, 4, c, True)
    elif kind == "clock":
        fb.ellipse(cx, cy, 7, 7, c); fb.vline(cx, cy - 5, 5, c); fb.hline(cx, cy, 4, c)
    elif kind == "flame":
        fb.poly(cx, cy, array("h", [0, -9, 5, -1, 4, 5, 0, 8, -4, 5, -5, -1]), c, True)

def card(fb, f, x, y, kind, col, value, label, unit="", w=110, h=50):
    rrect(fb, x, y, w, h, 10, CARD)
    fb.ellipse(x + 21, y + h // 2, 14, 14, c565(*mix(CARD, col, 0.28)), True)
    icon(fb, kind, x + 21, y + h // 2, col)
    xe = f["mid"].draw(fb, value, x + 42, y + 2, WHITE, CARD)
    if unit:
        f["small"].draw(fb, unit, xe + 3, y + 5, MUTED, CARD)
    f["small"].draw(fb, label, x + 42, y + 25, MUTED, CARD)

# ---------------------------------------------------------------- Bildschirme
def scr_boot(lcd, f, pct, msg):
    lcd.clear()
    f["mid"].draw(lcd, "THERMOGRIP", 120, 70, WHITE, bgcol(80), 1)
    f["small"].draw(lcd, "Hand warmer  ·  " + VERSION, 120, 100, MUTED, bgcol(105), 1)
    rrect(lcd, 30, 140, 180, 12, 6, RING_OFF)
    if pct > 0:
        rrect(lcd, 30, 140, max(12, int(180 * pct / 100)), 12, 6, ORANGE)
    f["mid"].draw(lcd, "%d %%" % pct, 120, 160, WHITE, bgcol(170), 1)
    f["small"].draw(lcd, msg, 120, 192, MUTED, bgcol(200), 1)
    lcd.show()

def scr_update(lcd, f, pct, msg):                          # V6.5: Update aus dem Internet
    lcd.clear()
    f["mid"].draw(lcd, "UPDATE", 120, 50, WHITE, bgcol(60), 1)
    f["small"].draw(lcd, "do not switch off", 120, 84, MUTED, bgcol(92), 1)
    rrect(lcd, 20, 118, 200, 28, 14, RING_OFF)
    if pct < 0:
        f["small"].draw(lcd, "failed", 120, 122, RED, RING_OFF, 1)
    else:
        if pct > 0:
            rrect(lcd, 20, 118, max(28, int(200 * pct / 100)), 28, 14, ORANGE)
        f["small"].draw(lcd, "%d %%" % pct, 120, 122, WHITE, ORANGE if pct >= 50 else RING_OFF, 1)
    f["small"].draw(lcd, msg[:28], 120, 170, MUTED, bgcol(178), 1)
    lcd.show()

def scr_main(lcd, f, d):
    lcd.clear()
    # Kopfzeile
    st, stc = d["status"]
    w = f["small"].width(st) + 22
    rrect(lcd, 8, 6, w, 20, 10, mix(bgcol(15), stc, 0.25))
    lcd.ellipse(18, 16, 3, 3, c565(*stc), True)
    f["small"].draw(lcd, st, 26, 5, stc, mix(bgcol(15), stc, 0.25))
    f["small"].draw(lcd, d["akku_txt"], 232, 5, MUTED, bgcol(15), 2)
    # Temperatur gross
    f["big"].draw(lcd, d["temp"], 8, 30, WHITE, bgcol(60))
    if d.get("nohand"):                                       # V6.4: ohne Handfuehler kein Raumwert
        f["small"].draw(lcd, "no hand", 88, 42, MUTED, bgcol(48))
        f["small"].draw(lcd, "sensor", 88, 62, MUTED, bgcol(68))
    f["small"].draw(lcd, d["ziel"], 12, 100, BLUE if not d["boost"] else ORANGE, bgcol(108))
    # Ring Heizleistung
    ring(lcd, d["duty"])
    f["mid"].draw(lcd, "%d%%" % d["duty"], 198, 49, WHITE, bgcol(60), 1)
    f["small"].draw(lcd, "Heater", 198, 98, MUTED, bgcol(106), 1)
    # Kacheln
    card(lcd, f, 8, 126, "bat", TEAL, d["cell"], "Cell", "V" if d["cell"] != "--" else "")   # V7.2: Einzelzelle statt Luefter
    card(lcd, f, 122, 126, "bat", d["akku_col"], d["akku"], "Battery", d["akku_u"])
    card(lcd, f, 8, 182, "temp", RED, d["matte"], "Pad", d["matte_u"])
    card(lcd, f, 122, 182, "clock", BLUE, d["rest"], "Left", d["rest_u"])
    if d["err"]:
        rrect(lcd, 8, 182, 224, 50, 10, RED)
        f["mid"].draw(lcd, d["err"], 120, 186, WHITE, RED, 1)
        f["small"].draw(lcd, d["err2"], 120, 210, WHITE, RED, 1)
    lcd.show()

def scr_standby(lcd, f, d):
    lcd.clear()
    f["small"].draw(lcd, d["akku_txt"], 232, 5, MUTED, bgcol(15), 2)
    lcd.ellipse(120, 62, 22, 22, c565(*mix(bgcol(62), BLUE, 0.25)), True)       # Power-Symbol
    lcd.ellipse(120, 62, 12, 12, c565(*BLUE)); lcd.ellipse(120, 62, 11, 11, c565(*BLUE))
    lcd.fill_rect(116, 44, 9, 12, c565(*mix(bgcol(62), BLUE, 0.25))); lcd.fill_rect(119, 46, 3, 16, c565(*BLUE))
    f["title"].draw(lcd, "STANDBY", 120, 92, WHITE, bgcol(115), 1)
    f["small"].draw(lcd, "Press A to start heating", 120, 146, MUTED, bgcol(155), 1)
    for i, (lab, val) in enumerate((("Hand", d["temp"]), ("Target", d["ziel_n"]), ("Battery", d["akku_n"]))):
        x = 8 + i * 76
        rrect(lcd, x, 180, 72, 54, 10, CARD)
        f["mid"].draw(lcd, val, x + 36, 184, WHITE, CARD, 1)
        f["small"].draw(lcd, lab, x + 36, 208, MUTED, CARD, 1)
    lcd.show()

def scr_stats(lcd, f, rows):
    lcd.clear()
    f["mid"].draw(lcd, "Statistics", 12, 6, WHITE, bgcol(15))
    f["small"].draw(lcd, VERSION, 228, 12, MUTED, bgcol(20), 2)      # V6.2: Firmware-Version
    rrect(lcd, 8, 40, 224, 192, 12, CARD)
    for i, (k, v) in enumerate(rows):
        y = 46 + i * 22
        f["small"].draw(lcd, k, 20, y, MUTED, CARD)
        f["small"].draw(lcd, v, 220, y, WHITE, CARD, 2)
    lcd.show()

# ---------------------------------------------------------------- Eingaben
class Keys:
    def __init__(self, swap=False):
        self.p = {k: Pin(n, Pin.IN, Pin.PULL_UP) for k, n in KEYS.items()}
        self.last = {k: 1 for k in KEYS}; self.t = {k: 0 for k in KEYS}
        self.swap = swap
    def pressed(self):
        out = []; now = time.ticks_ms()
        for k, p in self.p.items():
            v = p.value()
            if v == 0 and self.last[k] == 1 and time.ticks_diff(now, self.t[k]) > 150:
                out.append(k); self.t[k] = now
            elif v == 0 and k in ("UP", "DOWN", "LEFT", "RIGHT") and time.ticks_diff(now, self.t[k]) > 400:
                out.append(k); self.t[k] = now - 250
            self.last[k] = v
        if self.swap:
            m = {"UP": "DOWN", "DOWN": "UP", "LEFT": "RIGHT", "RIGHT": "LEFT"}
            out = [m.get(k, k) for k in out]
        return out

# ---------------------------------------------------------------- Messen
def ntc_temp(adc, beta):
    raw = sum(adc.read_u16() for _ in range(32)) / 32
    if raw < 300 or raw > 65200:
        return None
    r = 10000 * raw / (65535 - raw)
    t = 1 / (1 / 298.15 + math.log(r / 10000) / beta) - 273.15
    return t if -30 < t < 90 else None          # >90 °C = Fuehler fehlt/defekt (offener Eingang)

_flt = {}
def smooth(key, t, dt, tau):
    if t is None:
        _flt.pop(key, None); return None
    tau = max(0.1, tau)
    a = _flt.get(key)
    _flt[key] = t if a is None else a + (t - a) * dt / (tau + dt)
    return _flt[key]

def akku_volt(adc, cal):
    raw = sum(adc.read_u16() for _ in range(16)) / 16
    return raw / 65535 * 3.3 * (122 / 22) * cal

SOC_LIPO = ((3.50, 0), (3.60, 5), (3.70, 15), (3.75, 30), (3.80, 45), (3.85, 55), (3.95, 70), (4.05, 85), (4.20, 100))
SOC_LIION = [(3.0, 0), (3.2, 5), (3.4, 15), (3.5, 27), (3.6, 43), (3.7, 60), (3.8, 74), (3.9, 86), (4.0, 95), (4.1, 100)]   # voll = 4,1 V/Zelle (16,4 V bei 4S)
SOC = SOC_LIPO
def soc(vz):
    if vz <= SOC[0][0]: return 0
    for (v1, p1), (v2, p2) in zip(SOC, SOC[1:]):
        if vz <= v2:
            return p1 + (p2 - p1) * (vz - v1) / (v2 - v1)
    return 100

def fmt_t(t):
    return ("%.1f°" % t) if t is not None else "--°"

# ---------------------------------------------------------------- Hauptprogramm
def key_test(lcd, f, cfg):
    """Tastentest: A + Y beim Einschalten 2 s halten (oder key_test = 1). Beenden: A + Y erneut 2 s halten."""
    import machine
    pins = {k: Pin(n, Pin.IN, Pin.PULL_UP) for k, n in KEYS.items()}
    cnt = {k: 0 for k in KEYS}; last = {k: p.value() for k, p in pins.items()}
    bp = None
    try:
        if int(cfg.get("beeper_pin", -1)) >= 0:
            bp = PWM(Pin(int(cfg["beeper_pin"]))); bp.freq(int(cfg.get("beeper_hz", 2700))); bp.duty_u16(0)
    except Exception:
        bp = None
    # Position auf dem Bildschirm: Joystick links, Tasten rechts (wie am Display)
    JOY = {"UP": (62, 78), "DOWN": (62, 158), "LEFT": (22, 118), "RIGHT": (102, 118), "CTRL": (62, 118)}
    BTN = {"A": 66, "B": 104, "X": 142, "Y": 180}
    hold = 0; armed = False
    while True:
        st = {k: p.value() == 0 for k, p in pins.items()}
        for k in KEYS:
            if st[k] and last[k] == 1:
                cnt[k] += 1
                if bp: bp.duty_u16(32768); time.sleep_ms(25); bp.duty_u16(0)
            last[k] = 0 if st[k] else 1
        lcd.clear()
        f["mid"].draw(lcd, "Button test", 12, 6, WHITE, bgcol(15))
        for k, (x, y) in JOY.items():
            on = st[k]; col = ORANGE if on else CARD
            r = 18 if k == "CTRL" else 16
            lcd.ellipse(x, y, r, r, c565(*col), True)
            lab = {"UP": "UP", "DOWN": "DN", "LEFT": "LT", "RIGHT": "RT", "CTRL": "OK"}[k]
            f["small"].draw(lcd, lab, x, y - 10, WHITE, col, 1)
        f["small"].draw(lcd, "Joystick", 62, 186, MUTED, bgcol(190), 1)
        for k, y in BTN.items():
            on = st[k]; col = GREEN if on else CARD
            rrect(lcd, 150, y - 16, 82, 32, 9, col)
            f["mid"].draw(lcd, k, 170, y - 12, WHITE, col, 1)
            f["small"].draw(lcd, "%dx" % cnt[k], 224, y - 9, WHITE if on else MUTED, col, 2)
        f["small"].draw(lcd, "Hold A + Y for 2 s to exit", 120, 214, MUTED, bgcol(220), 1)
        lcd.show()
        if not st["A"] and not st["Y"]:
            armed = True                                    # erst loslassen, dann zaehlt A + Y als Beenden
        if armed and st["A"] and st["Y"]:
            hold += 1
            if hold > 40:
                lcd.clear(); f["mid"].draw(lcd, "Release buttons", 120, 108, WHITE, bgcol(110), 1); lcd.show()
                while pins["A"].value() == 0 or pins["Y"].value() == 0:
                    time.sleep_ms(20)
                time.sleep_ms(200); machine.reset()
        else:
            hold = 0
        time.sleep_ms(40)

def main():
    if Pin(KEYS["B"], Pin.IN, Pin.PULL_UP).value() == 0:
        print("Maintenance mode (B held) - program not started.")
        return
    heiz = PWM(Pin(P_HEIZ)); heiz.freq(1000); heiz.duty_u16(0)
    luef = PWM(Pin(P_LUEFTER)); luef.freq(1000); luef.duty_u16(0)

    f = load_fonts()                                        # V8.4: grosse Bloecke zuerst laden (sonst MemoryError durch zerstueckelten Speicher)
    cfg = load_cfg()
    gc.collect()
    lcd = LCD(int(cfg["display_rotate"]), cfg["brightness"])
    ring_init(198, 62, 27, 35)
    pa, py_ = Pin(KEYS["A"], Pin.IN, Pin.PULL_UP), Pin(KEYS["Y"], Pin.IN, Pin.PULL_UP)
    held = 0
    while pa.value() == 0 and py_.value() == 0 and held < 40:     # A + Y beim Einschalten 2 s halten
        if held == 0:
            scr_boot(lcd, f, 5, "Keep holding A + Y ...")
        held += 1; time.sleep_ms(50)
    if held >= 40 or int(cfg.get("key_test", 0)) == 1:
        key_test(lcd, f, cfg)

    scr_boot(lcd, f, 10, "Display ready")
    keys = Keys(int(cfg["display_rotate"]) == 180)
    adc_f, adc_h, adc_a = ADC(P_NTC_FOLIE), ADC(P_NTC_HAND), ADC(P_AKKU)
    scr_boot(lcd, f, 40, "Settings loaded")
    tf, th = ntc_temp(adc_f, cfg["ntc_beta"]), ntc_temp(adc_h, cfg["ntc_beta"])
    scr_boot(lcd, f, 70, "Pad %s · Hand %s" % ("OK" if tf is not None else "missing", "OK" if th is not None else "missing"))
    v = sum(akku_volt(adc_a, cfg["battery_calibration"]) for _ in range(5)) / 5
    zellen = 0 if v < 6 else (4 if v > 13.4 else 3)
    if zellen and int(cfg["battery_cells"]) in (3, 4):
        zellen = int(cfg["battery_cells"])               # fest eingestellt
    demo = zellen == 0 and cfg["demo_on_usb"]
    scr_boot(lcd, f, 100, "Battery %.1f V · %s" % (v, ("%dS detected" % zellen) if zellen else ("demo mode" if demo else "none")))
    time.sleep_ms(700)
    wdt = WDT(timeout=8000) if zellen else None              # nur mit echtem Akku (Heizen moeglich)
    web = None
    if int(cfg.get("wifi_enable", 0)) == 1:
        try:
            import web as webmod
            web = webmod.Web(cfg, ST)
        except Exception as e:
            print("WiFi off:", e)
    if demo:
        zellen = 4; sim = dict(tf=21.0, th=21.0, v=16.3)    # simulierte Werte

    ziel0 = cfg["target_temp_start"]
    if cfg.get("remember_target", 1) == 1:                    # V5.6: zuletzt eingestellte Temperatur
        try:
            ziel0 = int(float(open("last_target.txt").read().strip()))
        except (OSError, ValueError):
            pass
    ziel0 = min(cfg["target_temp_max"], max(cfg["target_temp_min"], ziel0))
    s = dict(on=zellen > 0, ziel=ziel0, fan=cfg["fan_percent"], fan_on=True,
             page=0, boost_bis=0, ziel_vor=0, integ=0.0, duty=0.0, err="", leer=False,
             wh=0.0, start=time.ticks_ms(), low_t=0, pavg=12.0)
    pmax = cfg["power_4s_max"] if zellen == 4 else cfg["power_3s_max"]
    r_heiz = 144 / max(1, cfg["heater_watts_12v"])
    last = time.ticks_ms(); draw_t = 0; idle_t = time.ticks_ms()
    LOCKUI["f"] = f; key_t = time.ticks_ms(); v_disp = 0; save_t = 0; saved_ziel = ziel0; a_n = 0; a_t = 0; hint_until = 0
    bp = None
    if int(cfg["beeper_pin"]) >= 0:
        if int(cfg["beeper_type"]) == 1:
            bp = PWM(Pin(int(cfg["beeper_pin"]))); bp.freq(50)
        elif int(cfg["beeper_type"]) == 2:
            bp = PWM(Pin(int(cfg["beeper_pin"]))); bp.freq(int(cfg["beeper_hz"])); bp.duty_u16(0)
        else:
            bp = Pin(int(cfg["beeper_pin"]), Pin.OUT, value=0)
    beep_until = 0; beep_t = 0
    def beep(on):
        if bp is None: return
        if int(cfg["beeper_type"]) == 1:
            bp.duty_ns(int((cfg["beeper_on_us"] if on else cfg["beeper_off_us"]) * 1000))
        elif int(cfg["beeper_type"]) == 2:
            bp.duty_u16(32768 if on else 0)
        else:
            bp.value(1 if on else 0)
    beep(False)

    def power_off(reason):
        heiz.duty_u16(0); luef.duty_u16(0); beep(False)
        lcd.clear(); f["title"].draw(lcd, "OFF", 120, 70, WHITE, bgcol(95), 1)
        f["small"].draw(lcd, reason, 120, 140, MUTED, bgcol(150), 1); lcd.show(); time.sleep_ms(2500)
        if int(cfg["power_off_pin"]) >= 0:
            Pin(int(cfg["power_off_pin"]), Pin.OUT, value=1)     # Pololu trennt den Akku
            time.sleep_ms(500)
        lcd.light(0)                                             # ohne Pololu: Display aus, warten auf Taste
        while not keys.pressed():
            if wdt: wdt.feed()
            time.sleep_ms(100)
        lcd.light(cfg["brightness"])

    while True:
        if wdt: wdt.feed()
        if web:
            web.poll(wdt.feed if wdt else None, s["on"])
            if web.want and web.man and (not s["on"] or web.force):   # V6.5: Update installieren (Heizung aus)
                s["on"] = False; heiz.duty_u16(0); luef.duty_u16(0); beep(False)
                web.install(lambda p, m: scr_update(lcd, f, p, m), wdt.feed if wdt else None)
                for _ in range(15):                               # nur bei Fehler: Meldung 3 s stehen lassen
                    if wdt: wdt.feed()
                    time.sleep_ms(200)
                draw_t = 0
        now = time.ticks_ms(); dt = max(0.01, time.ticks_diff(now, last) / 1000); last = now

        pk = keys.pressed()
        # --- Tastensperre: nach key_lock_seconds ohne Eingabe; entsperren mit 3x A (innerhalb 3 s)
        if LOCKUI["on"]:
            if pk:
                hint_until = time.ticks_add(now, 3000)
            if a_n and time.ticks_diff(now, a_t) > 3000:
                a_n = 0
            if "A" in pk:
                a_n += 1; a_t = now
                beep(True); time.sleep_ms(25); beep(False)
                if a_n >= 3:
                    LOCKUI["on"] = False; key_t = now; a_n = 0; hint_until = 0; draw_t = 0
                    time.sleep_ms(80); beep(True); time.sleep_ms(120); beep(False)
            LOCKUI["hint"] = (("Unlocking %d/3" % a_n) if a_n else "Buttons locked") if time.ticks_diff(hint_until, now) > 0 else ""
            pk = []
        else:
            if pk: key_t = now
            if cfg["key_lock_seconds"] > 0 and time.ticks_diff(now, key_t) > cfg["key_lock_seconds"] * 1000:
                LOCKUI["on"] = True; draw_t = 0; s["page"] = 0     # V5.5: beim Sperren Startseite
        if web and web.keys:                                  # V7.6: Tasten von der Webseite (ohne Tastensperre)
            pk = list(pk) + web.keys; web.keys = []
            if s["page"] == 1: s["page"] = 0
        if pk or s["on"]:
            idle_t = now
        for k in pk:
            if s["page"] == 1:                                # Statistik: jede Taste -> zurueck
                s["page"] = 0
                continue
            if k in ("A", "CTRL"):
                if s["boost_bis"]:
                    s["ziel"] = s["ziel_vor"]; s["boost_bis"] = 0
                if s["err"].startswith("Pad too hot") or s["err"].startswith("Heater not"):
                    s["err"] = ""; s["chk_t"] = 0; s["chk_base"] = None
                s["on"] = not s["on"] and zellen > 0 and not s["leer"]
                s["integ"] = 0
            elif k == "B": s["page"] = 1 - s["page"]
            elif k == "X": s["fan_on"] = not s["fan_on"]
            elif k == "Y" and s["boost_bis"]:                  # Boost abbrechen
                s["ziel"] = s["ziel_vor"]; s["boost_bis"] = 0; s["integ"] = 0
            elif k == "Y" and s["on"]:
                s["ziel_vor"] = s["ziel"]
                s["ziel"] = cfg["target_temp_max"]; s["boost_bis"] = time.ticks_add(now, int(cfg["boost_minutes"] * 60000))
            elif k in ("UP", "DOWN"):
                if s["boost_bis"]:                            # Boost beenden, vom alten Wert aus weiter
                    s["ziel"] = s["ziel_vor"]; s["boost_bis"] = 0
                s["ziel"] = min(cfg["target_temp_max"], max(cfg["target_temp_min"], s["ziel"] + (1 if k == "UP" else -1)))
                if k == "DOWN": s["integ"] = min(s["integ"], 0)
                save_t = time.ticks_add(now, 5000)            # 5 s nach der letzten Aenderung speichern
            elif k == "RIGHT": s["fan"] = min(100, s["fan"] + 10)
            elif k == "LEFT": s["fan"] = max(0, s["fan"] - 10)
        if s["boost_bis"] and time.ticks_diff(now, s["boost_bis"]) > 0:
            s["ziel"] = s["ziel_vor"]; s["boost_bis"] = 0; s["integ"] = 0
        if save_t and time.ticks_diff(now, save_t) > 0:
            save_t = 0
            if cfg.get("remember_target", 1) == 1 and not s["boost_bis"] and s["ziel"] != saved_ziel:
                try:
                    with open("last_target.txt", "w") as fh:
                        fh.write("%d\n" % s["ziel"])
                    saved_ziel = s["ziel"]
                except OSError:
                    pass

        if demo:                                              # echte Fuehler nutzen, wenn angesteckt
            tf, th = ntc_temp(adc_f, cfg["ntc_beta"]), ntc_temp(adc_h, cfg["ntc_beta"])
            s["real_f"], s["real_h"] = tf is not None, th is not None
            if tf is None: tf = sim["tf"]
            if th is None: th = sim["th"]
            v = sim["v"]
        else:
            tf, th = ntc_temp(adc_f, cfg["ntc_beta"]), ntc_temp(adc_h, cfg["ntc_beta"])
            v = akku_volt(adc_a, cfg["battery_calibration"])
        tf, th = smooth("f", tf, dt, cfg["temp_smooth_s"]), smooth("h", th, dt, cfg["temp_smooth_s"])     # Rauschen glaetten (Zeitkonstante temp_smooth_s)
        vz = v / zellen if zellen else 0

        if tf is None:
            s["err"] = "Pad sensor missing"
        elif tf > cfg["pad_temp_max"] + 5:
            s["err"] = "Pad too hot!"
        elif s["err"].startswith("Pad sensor"):
            s["err"] = ""
        if zellen and (vz < cfg["off_cell_volts"] - 0.15 or (vz < cfg["off_cell_volts"] and s["duty"] < 5)):
            s["low_t"] += dt
        else:
            s["low_t"] = 0
        if s["low_t"] > 3:
            s["leer"] = True; s["on"] = False
        if s["leer"] and s["low_t"] > 60 and not demo:
            power_off("Battery empty")                            # Akku schuetzen
        if cfg["auto_off_minutes"] > 0 and not s["on"] and time.ticks_diff(now, idle_t) > cfg["auto_off_minutes"] * 60000:
            power_off("Auto off after %d min standby" % cfg["auto_off_minutes"]); idle_t = time.ticks_ms()

        if cfg["power_auto"] and zellen and v > 5:            # Leistung nach Spannung: Matte bekommt nie mehr als ihre Nennleistung
            v_p = smooth("vp", v, dt, 3)
            pmax = max(5, min(100, 100 * (cfg["pad_volts"] / v_p) ** 2))
        duty = 0.0
        if s["on"] and not s["err"] and not s["leer"]:
            if th is not None:
                e = s["ziel"] - th
            else:                                             # V6.1: ohne Handfuehler Matte auf Ziel + no_hand_offset regeln
                e = min(cfg["pad_temp_max"], s["ziel"] + cfg.get("no_hand_offset", 18)) - tf
            raw = cfg["control_kp"] * e + s["integ"]
            if (0 < raw < pmax) or (raw >= pmax and e < 0) or (raw <= 0 and e > 0):
                s["integ"] = max(-20, min(60, s["integ"] + e * cfg["control_ki"] * dt))   # Anti-Windup
            lim = cfg["pad_temp_max"]
            if th is not None and cfg["pad_temp_hold"] > 0:   # Ziel erreicht -> Matte max. pad_temp_hold, je kaelter die Hand, desto mehr (bis pad_temp_max)
                k = max(0, min(1, (s["ziel"] - th) / max(1, cfg["pad_full_below"])))
                lim = min(lim, cfg["pad_temp_hold"] + (cfg["pad_temp_max"] - cfg["pad_temp_hold"]) * k)
            if cfg["pad_over_target"] > 0:
                lim = min(lim, s["ziel"] + cfg["pad_over_target"])
            s["pad_lim"] = lim
            grenze_matte = (lim - tf) * 20
            duty = max(0, min(cfg["control_kp"] * e + s["integ"], pmax, grenze_matte))
        else:
            s["integ"] = 0
        s["duty"] = duty
        # --- Heizungs-Pruefung: kraeftig geheizt, aber Matte wird nicht waermer bzw. kuehlt ab
        #     -> Matte/Thermosicherung/Kabel defekt oder Fuehler hat keinen Kontakt zur Matte
        if not s["on"] or tf is None or s["err"]:
            s["chk_t"] = 0; s["chk_base"] = None
        else:
            if s.get("chk_base") is None or duty < 25:
                s["chk_base"] = s["chk_peak"] = tf; s["chk_t"] = 0
            s["chk_peak"] = max(s["chk_peak"], tf)
            bad = (s["chk_peak"] - s["chk_base"] < cfg["heater_check_rise"]) or (tf < s["chk_peak"] - 3)
            if cfg["heater_check_minutes"] > 0 and duty >= 40 and bad:
                if not s.get("chk_t"):
                    s["chk_t"] = now
                elif time.ticks_diff(now, s["chk_t"]) > cfg["heater_check_minutes"] * 60000:
                    s["err"] = "Heater not working"; s["chk_t"] = 0; s["chk_base"] = None
            else:
                s["chk_t"] = 0
        fan = s["fan"] if s["on"] and s["fan_on"] and (duty > 0 or not cfg["fan_auto"]) else 0   # Heizung aus -> Luefter aus
        if demo:                                              # nichts ansteuern, nur rechnen
            heiz.duty_u16(0); luef.duty_u16(0)
            sim["tf"] += (duty / 100 * 1.5 - (sim["tf"] - 21) * 0.03) * dt
            sim["th"] += ((sim["tf"] - sim["th"]) * 0.06 - (sim["th"] - 21) * 0.01 - fan * 0.0002 * (sim["th"] - 21)) * dt
            sim["v"] = max(13.6, sim["v"] - duty / 100 * 0.0006 * dt - 0.00002 * dt)
        else:
            heiz.duty_u16(int(duty * 655.35))
            luef.duty_u16(int(fan * 655.35))

        # --- Beeper: Fehler 1 s alle 5 s, Akku leer 1 s alle 50 s; Akku-Warnung 2x kurz piepen, dann 1 min Pause
        alarm = bool(s["err"]) or s["leer"]
        vw = s.get("pct_v", vz)
        warn = zellen and not demo and vw < cfg["warn_cell_volts"]
        if alarm:
            if time.ticks_diff(now, beep_t) > (50000 if s["leer"] and not s["err"] else 5000):   # Akku leer: alle 50 s, Fehler: alle 5 s
                beep_t = now; beep_until = time.ticks_add(now, 1000)
            beep(time.ticks_diff(beep_until, now) > 0)
        elif warn:
            if time.ticks_diff(now, beep_t) > 60000 or beep_t == 0:
                beep_t = now
            ph = time.ticks_diff(now, beep_t)
            beep(ph < 150 or 300 <= ph < 450)
        else:
            beep(False)

        p = duty / 100 * v * v / r_heiz if zellen else 0
        s["wh"] += p * dt / 3600
        s["pavg"] += (max(p, 1.0) - s["pavg"]) * min(1, dt / 600)     # V7.1: Leistung ueber ~10 min mitteln
        vz_s = smooth("v", vz, dt, cfg["battery_smooth_s"]) if zellen else 0     # Spannung glaetten (springt unter Last)
        if zellen and (v_disp == 0 or abs(vz_s * zellen - v_disp) >= 0.1):         # V6.6: Anzeige ruhig (geglaettet + 0,1 V Hysterese)
            v_disp = round(vz_s * zellen, 1)
        s["pct_v"] = vz_s
        pct_now = soc(vz_s) if zellen else 0
        if "pct" not in s or not zellen:
            s["pct"] = pct_now
        elif pct_now < s["pct"] - 0.5 or pct_now > s["pct"] + 3:               # nur in ganzen Schritten nach unten, erholt sich nur bei deutlichem Anstieg
            s["pct"] = pct_now
        akku_pct = int(s["pct"] + 0.5)
        rest_now = s["pct"] / 100 * cfg["battery_mah"] / 1000 * 3.7 * zellen / s["pavg"] * 60 if zellen else 0
        s["rest"] = rest_now if "rest" not in s else s["rest"] + (rest_now - s["rest"]) * min(1, dt / 120)
        rest_min = int(s["rest"] / 5 + 0.5) * 5 if zellen else 0          # V7.1: in 5-min-Schritten

        if web:
            ST.update(temp=None if th is None else round(th, 1), target=s["ziel"], pad=None if tf is None else round(tf, 1),
                      heater=int(duty), battery=akku_pct if zellen else None, volts=v_disp if zellen else None, cell=round(vz_s, 2) if zellen else None,
                      cells=zellen or None, left=rest_min if zellen else None,
                      on=s["on"], boost=bool(s["boost_bis"]), tmin=cfg["target_temp_min"], tmax=cfg["target_temp_max"],
                      pmax=cfg["pad_temp_max"], phold=cfg["pad_temp_hold"], plim=int(round(s.get("pad_lim", cfg["pad_temp_max"]))), mem=gc.mem_free() // 1024,
                      state=(s["err"] or ("Battery empty" if s["leer"] else ("Heating" if s["on"] else "Standby")) + (" (demo)" if demo else "")))
        if time.ticks_diff(now, draw_t) > 250:
            draw_t = now
            if s["page"] == 0 and not s["on"] and not s["err"] and not s["leer"] and zellen:
                scr_standby(lcd, f, dict(akku_txt=("DEMO · " if demo else "") + "%dS · %.1f V" % (zellen, v_disp),
                                         temp=fmt_t(th if th is not None else tf), ziel_n="%d°" % s["ziel"],
                                         akku_n="%d%%" % akku_pct))
            elif s["page"] == 0:
                if demo and not s["leer"]: status = (("SENSOR LIVE" if s.get("real_h") or s.get("real_f") else "DEMO") + ("" if s["on"] else " OFF"), BLUE)
                elif s["leer"]: status = ("BATTERY EMPTY", RED)
                elif not s["on"]: status = ("OFF", MUTED)
                elif s["boost_bis"]: status = ("BOOST", ORANGE)
                else: status = ("HEATING", ORANGE)
                if s["boost_bis"]:
                    rs = max(0, time.ticks_diff(s["boost_bis"], now) // 1000)
                    ziel = "Boost %d° %d:%02d" % (s["ziel"], rs // 60, rs % 60)
                else:
                    ziel = "Target %d °C" % s["ziel"]
                err, err2 = "", ""
                if s["err"]:
                    err = s["err"]; err2 = "Press A to reset" if ("hot" in err or "not working" in err) else "Heater is off"
                elif s["leer"]:
                    err, err2 = "Battery empty", "Heater is off"
                low = zellen and vz < cfg["warn_cell_volts"]
                scr_main(lcd, f, dict(
                    status=status, akku_txt=(("%dS · %.1f V" % (zellen, v_disp)) ) if zellen else "USB only",
                    temp=fmt_t(th), nohand=th is None, ziel=ziel, boost=bool(s["boost_bis"]),
                    duty=duty, cell=("%.2f" % vz_s) if zellen else "--", fan=("%d" % s["fan"]) if s["fan_on"] else "off", fan_u="%" if s["fan_on"] else "",
                    akku=("%d" % akku_pct) if zellen else "--", akku_u="%" if zellen else "", akku_col=RED if low else GREEN,
                    matte=(("%d" % tf) if tf is not None else "--"), matte_u="°C" if tf is not None else "",
                    rest=("%d:%02d" % (rest_min // 60, rest_min % 60)) if zellen else "--", rest_u="h" if zellen else "", err=err, err2=err2))
            else:
                mins = time.ticks_diff(now, s["start"]) // 60000
                scr_stats(lcd, f, [("Time", "%d min · %.1f Wh" % (mins, s["wh"])),
                                   ("Power", "%.1f W" % p), ("Cell voltage", "%.2f V" % vz),
                                   ("Pad", fmt_t(tf) + "C"), ("Hand", fmt_t(th) + "C"),
                                   ("Pad limit", "%d °C" % s.get("pad_lim", cfg["pad_temp_max"])), ("Power limit", "%d %%" % int(pmax)), ("WiFi", web.text() if web else "off")])
            gc.collect()
        time.sleep_ms(20)

if __name__ == "__main__":
    try:
        main()
    except Exception as e:                                  # Fehler sichtbar machen statt haengen
        import sys
        PWM(Pin(P_HEIZ)).duty_u16(0)
        with open("error.txt", "w") as fh:
            sys.print_exception(e, fh)
        sys.print_exception(e)
        try:
            lcd = LCD()
            lcd.fill(c565(150, 20, 20)); lcd.text("ERROR - see error.txt", 8, 100, 0xFFFF)
            lcd.text(str(e)[:28], 8, 120, 0xFFFF); lcd.text("restart in 8 s", 8, 140, 0xFFFF); lcd.show()
        except Exception:
            pass
        time.sleep(8)                                       # V8.3: nach Absturz automatisch neu starten
        import machine
        machine.reset()
