#!/usr/bin/env python3
# Erzeugt manifest.json aus den Dateien im Repository.
# Aufruf: python3 tools/manifest.py V1.6.81
import hashlib, json, os, sys
R = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
ver = sys.argv[1]
def md5(p): return hashlib.md5(open(p, 'rb').read()).hexdigest()
fw = f"firmware/Core_{ver}.bin"; fp = os.path.join(R, fw)
m = {"fw": ver, "fwDatei": fw, "fwGroesse": os.path.getsize(fp), "fwMd5": md5(fp), "dateien": [], "loeschen": ["/player.html"]}
for wurzel, _, dateien in os.walk(os.path.join(R, "sd")):
    for n in sorted(dateien):
        p = os.path.join(wurzel, n); rel = os.path.relpath(p, R).replace(os.sep, "/")
        m["dateien"].append({"p": "/" + rel[3:], "url": rel, "s": os.path.getsize(p), "md5": md5(p)})
m["dateien"].sort(key=lambda d: d["p"])
json.dump(m, open(os.path.join(R, "manifest.json"), "w"), indent=1, ensure_ascii=False)
print(json.dumps(m, indent=1)[:1500])
