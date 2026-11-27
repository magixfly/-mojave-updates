#!/usr/bin/env python3
"""Passes the settings page of the LTE stick through the Pi.

The stick is only reachable from the Pi (USB network). This small forwarder
listens on the Pi and hands every connection on to the stick, so the page can
be opened from the notebook as http://<pi>:8081/

Optional lines in /boot/firmware/fpv-config.txt:
  stick_page_port = 8081          port on the Pi (0 = switched off)
  stick_page_addr = 192.168.100.1 address of the stick
"""
import asyncio, re, sys

CFG = "/boot/firmware/fpv-config.txt"
port, addr = 8081, "192.168.100.1"
try:
    for line in open(CFG, encoding="utf-8", errors="replace"):
        m = re.match(r"\s*(stick_page_port|stick_page_addr)\s*=\s*([^#\s]+)", line)
        if m and m.group(1) == "stick_page_port":
            port = int(m.group(2))
        elif m:
            addr = m.group(2)
except (OSError, ValueError):
    pass
if len(sys.argv) > 2:                       # test: stickpage.py <port> <addr[:port]>
    port, addr = int(sys.argv[1]), sys.argv[2]
host, _, tport = addr.partition(":")
tport = int(tport or 80)


async def pipe(r, w):
    try:
        while data := await r.read(65536):
            w.write(data)
            await w.drain()
    except (ConnectionError, OSError):
        pass
    finally:
        try:
            w.close()
        except OSError:
            pass


async def handle(cr, cw):
    try:
        sr, sw = await asyncio.wait_for(asyncio.open_connection(host, tport), 6)
    except (OSError, asyncio.TimeoutError):
        cw.write(b"HTTP/1.1 502 Bad Gateway\r\nContent-Type: text/plain\r\nConnection: close\r\n\r\n"
                 b"The LTE stick does not answer. Is it plugged into the Pi?\n")
        await cw.drain()
        cw.close()
        return
    await asyncio.gather(pipe(cr, sw), pipe(sr, cw))


async def main():
    if port <= 0:
        print("[stickpage] switched off (stick_page_port = 0)", flush=True)
        await asyncio.Event().wait()
    srv = await asyncio.start_server(handle, "0.0.0.0", port)
    print(f"[stickpage] port {port} -> {host}:{tport}", flush=True)
    async with srv:
        await srv.serve_forever()

asyncio.run(main())
